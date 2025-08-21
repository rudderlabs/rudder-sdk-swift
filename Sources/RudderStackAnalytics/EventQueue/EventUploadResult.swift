//
//  EventUploadResult.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 21/08/25.
//

import Foundation

// MARK: - EventUploadResult
/**
 Represents the result of an event upload operation.
 */
enum EventUploadResult {
    case success(Data)
    case failure(EventUploadError)
}

// MARK: - EventUploadError
/**
 Represents an error that occurred during event upload.
 It can be either a retryable error or a non-retryable error.
 */
protocol EventUploadError: Error {}

/**
 Represents an event upload error that can be retried.
 */
protocol RetryableError: EventUploadError {}

/**
 Represents an event upload error that cannot be retried.
 */
protocol NonRetryableError: EventUploadError {}

/**
 Represents different types of retryable event upload errors.
 */
enum RetryableEventUploadError: RetryableError {
    case retryable(statusCode: Int?)
    case networkUnavailable
    case unknown
    
    var statusCode: Int? {
        return switch self {
        case .retryable(let code): code
        case .networkUnavailable, .unknown: nil
        }
    }
}

/**
 Represents different types of non-retryable event upload errors.
 */
enum NonRetryableEventUploadError: Int, NonRetryableError {
    case error400 = 400
    case error401 = 401
    case error404 = 404
    case error413 = 413
}
