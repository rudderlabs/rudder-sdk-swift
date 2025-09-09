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
    
    /** Indicates a retryable error, typically associated with HTTP status code 4xx-5xx, excluding non-retryable errors. */
    case retryable(statusCode: Int?)
    
    /** Indicates a retryable error, typically happens when the network is unavailable. */
    case networkUnavailable
    
    /** Indicates a fatal error, typically associated with some exception or failure that can be retried. */
    case unknown
    
    var statusCode: Int? {
        switch self {
        case .retryable(let code): code
        case .networkUnavailable, .unknown: nil
        }
    }
}

/**
 Represents different types of non-retryable event upload errors.
 */
enum NonRetryableEventUploadError: Int, NonRetryableError {
    
    /** Indicates a bad request error, typically associated with HTTP status code 400. */
    case error400 = 400
    
    /** Indicates an invalid write key error, typically associated with HTTP status code 401. */
    case error401 = 401
    
    /** Indicates that the requested resource was not found, typically associated with HTTP status code 404. */
    case error404 = 404
    
    /** Indicates that the request payload is too large, typically associated with HTTP status code 413. */
    case error413 = 413
    
    var formatStatusCodeMessage: String {
        "Status code: \(self.rawValue)"
    }
}
