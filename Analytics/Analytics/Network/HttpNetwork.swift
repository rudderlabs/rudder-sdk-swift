//
//  HttpNetwork.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/09/24.
//

import Foundation

// MARK: - HttpNetworkError
/**
 Enum for basic network error states.
 */
enum HttpNetworkError: Error {
    case requestFailed(Int)
    case invalidResponse
}

// MARK: - HttpNetwork
/**
 This class handles all network calls, returning either response data or an error.
 */
final class HttpNetwork {
    
    private init() {
        /* Prevent instantiation (no-op) */
    }
    
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration)
    }()
    
    static func perform(request: URLRequest) async throws -> Data {
        LoggerAnalytics.debug(log: "Request URL: \(request.url?.absoluteString ?? "No URL")")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw HttpNetworkError.invalidResponse }
        
        let statusCode = httpResponse.statusCode
        
        LoggerAnalytics.debug(log: "Response Status Code: \(statusCode)")
        LoggerAnalytics.debug(log: "Response Data: \(data.jsonString ?? "No Data")")
        
        guard statusCode == HttpStateCode.success else {
            throw HttpNetworkError.requestFailed(statusCode)
        }
        
        return data
    }
}

// MARK: - HttpStateCode
/**
 Struct representing common HTTP status codes.
 */
struct HttpStateCode {
    
    private init() {
        /* Prevent instantiation (no-op) */
    }

    static let success = 200
    static let notFound = 404
}
