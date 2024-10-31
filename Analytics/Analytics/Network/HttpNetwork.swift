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
    
    private init() {}
    
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration)
    }()
    
    static func perform(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw HttpNetworkError.invalidResponse }
        
        let statusCode = httpResponse.statusCode
        guard statusCode == 200 else {
            print(data.jsonString ?? "No Data..")
            throw HttpNetworkError.requestFailed(statusCode)
        }
        
        return data
    }
}
