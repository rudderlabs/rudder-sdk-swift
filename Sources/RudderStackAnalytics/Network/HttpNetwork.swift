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
    case networkUnavailable
    case unknown
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
    
    static func perform(request: URLRequest) async -> Result<Data, Error> {
        LoggerAnalytics.debug(log: "Request URL: \(request.url?.absoluteString ?? "No URL")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(HttpNetworkError.invalidResponse)
            }
            
            let statusCode = httpResponse.statusCode
            
            LoggerAnalytics.debug(log: "Response Status Code: \(statusCode)")
            LoggerAnalytics.debug(log: "Response Data: \(data.jsonString ?? "No Data")")
            
            guard statusCode == HttpStateCode.success else {
                return .failure(HttpNetworkError.requestFailed(statusCode))
            }
            
            return .success(data)
        } catch {
            // Check if the error is network-related
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
                        .timedOut, .dnsLookupFailed, .cannotFindHost, .dataNotAllowed:
                    return .failure(HttpNetworkError.networkUnavailable)
                default:
                    break
                }
            }
            
            // Return the original error if it's already an HttpNetworkError
            if let httpNetworkError = error as? HttpNetworkError {
                return .failure(httpNetworkError)
            }
            
            // For any other errors, return unknownError
            return .failure(HttpNetworkError.unknown)
        }
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
