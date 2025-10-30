//
//  SourceConfigResult.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 15/09/25.
//

import Foundation

// MARK: - SourceConfigResult
/**
 Represents the result of a source configuration fetch operation.
 */
enum SourceConfigResult {
    case success(Data)
    case failure(SourceConfigError)
}

// MARK: - SourceConfigError
/**
 Represents errors that can occur during the source configuration fetch operation.
 */
enum SourceConfigError: Error, Equatable {
    case invalidWriteKey
    case networkUnavailable
    case invalidResponse
    case unknown
    case requestFailed(Int)
    
    var errorDescription: String {
        switch self {
        case .invalidWriteKey:
            return "Invalid write key (HTTP 400)"
        case .networkUnavailable:
            return "Network unavailable"
        case .invalidResponse:
            return "Invalid server response"
        case .requestFailed(let statusCode):
            return "Request failed with status code: \(statusCode)"
        case .unknown:
            return "Unknown error"
        }
    }
}
