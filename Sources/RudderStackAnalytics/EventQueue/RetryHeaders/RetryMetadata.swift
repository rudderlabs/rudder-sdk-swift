//
//  RetryMetadata.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 16/02/26.
//

import Foundation

// MARK: - RetryMetadata
/**
 Models persisted retry state for batch upload retry headers.
 
 Used to track retry attempts across the upload loop and app restarts.
 */
struct RetryMetadata: Codable, Equatable {
    /** Unique identifier used to detect stale metadata when batches are evicted. */
    let batchId: String
    
    /** Current retry attempt number (1 = first retry). */
    let attempt: Int
    
    /** Milliseconds since epoch when the last attempt was made. */
    let lastAttemptTimestampInMillis: UInt64
    
    /** Categorised failure reason from last attempt. */
    let reason: String
}

// MARK: - JSON Serialization
extension RetryMetadata {
    func toJson() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.jsonString
    }
    
    static func fromJson(_ jsonString: String) -> RetryMetadata? {
        guard let data = jsonString.utf8Data else { return nil }
        return try? JSONDecoder().decode(RetryMetadata.self, from: data)
    }
}
