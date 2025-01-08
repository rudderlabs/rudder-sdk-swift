//
//  HttpClient.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/09/24.
//

import Foundation

// MARK: - HttpClientRequests
/**
 This protocol is designed to execute predefined network requests.
 */
protocol HttpClientRequests {
    func getConfiguarationData() async throws -> Data
    func postBatchEvents(_ batch: String) async throws -> Data
}

enum HttpClientError: Error {
    case invalidRequest
}

// MARK: - HttpClient
/**
 This class provides the implementation for the `HttpClientRequests` protocol.
 */
final class HttpClient {
    let analytics: AnalyticsClient
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    private func prepareGenericUrlRequest(for requestType: HttpClientRequestType) -> URLRequest? {
        guard let url = self.prepareRequestUrl(for: requestType) else { return nil }
        var urlRequest = URLRequest(url:url)
        urlRequest.httpMethod = requestType.httpMethod
        urlRequest.allHTTPHeaderFields = requestType.headers(analytics)
        return urlRequest
    }
    
    private func prepareRequestUrl(for requestType: HttpClientRequestType) -> URL? {
        guard var url = URL(string: requestType.url(analytics).trimmedUrlString) else { return nil }
        url = url.appendingPathComponent(requestType.endpoint)
        
        if requestType == .configuration {
            url = url.appendQueryParameters(Constants.configQueryParams)
        }
        return url
    }
}

// MARK: - HttpClientRequests
extension HttpClient: HttpClientRequests {
    func getConfiguarationData() async throws -> Data {
        guard let urlRequest = self.prepareGenericUrlRequest(for: .configuration) else { throw HttpClientError.invalidRequest }
        return try await HttpNetwork.perform(request: urlRequest)
    }
    
    func postBatchEvents(_ batch: String) async throws -> Data {
        guard var urlRequest = self.prepareGenericUrlRequest(for: .events) else { throw HttpClientError.invalidRequest }
        urlRequest.httpBody = batch.utf8Data
        
        if self.analytics.configuration.gzipEnabled, let gzipped = try? urlRequest.httpBody?.gzipped() as? Data {
            urlRequest.httpBody = gzipped
        }
        
        return try await HttpNetwork.perform(request: urlRequest)
    }
}

// MARK: - HttpClientRequestType
/**
 An enume that provides all network request-related data based on the request type.
 */
enum HttpClientRequestType {
    case configuration
    case events
    
    func url(_ analytics: AnalyticsClient) -> String {
        return switch self {
        case .configuration: analytics.configuration.controlPlaneUrl
        case .events: analytics.configuration.dataPlaneUrl
        }
    }
    
    var endpoint: String {
        return switch self {
        case .configuration: "sourceConfig"
        case .events: "v1/batch"
        }
    }
    
    var httpMethod: String {
        return switch self {
        case .configuration: "GET"
        case .events: "POST"
        }
    }
    
    func headers(_ analytics: AnalyticsClient) -> [String: String] {
        
        let encodedAuthString = (analytics.configuration.writeKey + ":").base64Encoded ?? ""
        var defaultHeaders = ["Content-Type": "application/json", "Authorization": "Basic \(encodedAuthString)"]
        
        if self == .events {
            var specialHeaders = ["AnonymousId": analytics.anonymousId]
            if analytics.configuration.gzipEnabled { specialHeaders["Content-Encoding"] = "gzip" }
            specialHeaders.forEach { defaultHeaders[$0] = $1 }
        }
        
        return defaultHeaders
    }
}
