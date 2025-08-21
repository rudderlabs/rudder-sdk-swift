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
protocol RetryAbleError: EventUploadError {}

/**
Represents an event upload error that cannot be retried.
 */
protocol NonRetryAbleError: EventUploadError {}

/**
Represents different types of retryable event upload errors.
 */
enum RetryAbleEventUploadError: RetryAbleError {
    case errorRetry(statusCode: Int?)
    case errorNetworkUnavailable
    case errorUnknown
    
    var statusCode: Int? {
        switch self {
        case .errorRetry(let code): return code
        case .errorNetworkUnavailable, .errorUnknown: return nil
        }
    }
}

/**
Represents different types of non-retryable event upload errors.
 */
enum NonRetryAbleEventUploadError: Int, NonRetryAbleError {
    case error400 = 400
    case error401 = 401
    case error404 = 404
    case error413 = 413
}
