//
//  RetryHeadersProvider.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 17/02/26.
//

import Foundation

/**
 Provides retry headers for event batch upload requests.
 
 On retry attempts (not the first attempt), this provider returns headers containing:
 - `Rsa-Retry-Attempt`: Current retry attempt number (1 for first retry)
 - `Rsa-Since-Last-Attempt`: Time elapsed since last attempt in milliseconds
 - `Rsa-Retry-Reason`: Categorised reason for the retry
 */
protocol RetryHeadersProvider {
    /** Returns retry headers for the current upload attempt, or an empty dictionary if no prior failure is recorded. */
    func prepareHeaders(batchId: Int, currentTimestampInMillis: UInt64) -> [String: String]
    
    /** Records a failed upload attempt for retry tracking. */
    func recordFailure(batchId: Int, timestampInMillis: UInt64, error: RetryableEventUploadError)
    
    /** Clears all persisted retry metadata. */
    func clear()
}

/**
 Keys for retry headers used in event batch upload requests.
 */
enum RetryHeaderKeys {
    static let rsaRetryAttempt = "Rsa-Retry-Attempt"
    static let rsaSinceLastAttempt = "Rsa-Since-Last-Attempt"
    static let rsaRetryReason = "Rsa-Retry-Reason"
}
