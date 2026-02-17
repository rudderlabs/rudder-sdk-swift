//
//  PrimaryRetryHeadersProvider.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 17/02/26.
//

import Foundation

/**
 Default implementation of `RetryHeadersProvider` protocol.
 */
final class PrimaryRetryHeadersProvider: RetryHeadersProvider {
    
    private let storage: KeyValueStorage
    
    init(storage: KeyValueStorage) {
        self.storage = storage
    }
    
    func prepareHeaders(batchId: String, currentTimestampInMillis: UInt64) -> [String : String] {
        guard let metadata = self.retrieveMetadataForBatch(batchId) else { return [:] }
        
        let sinceLastAttemptInMillis: UInt64 = currentTimestampInMillis > metadata.lastAttemptTimestampInMillis
        ? currentTimestampInMillis - metadata.lastAttemptTimestampInMillis
        : 0
        
        LoggerAnalytics.verbose("Adding retry headers: attempt=\(metadata.attempt), sinceLastAttempt=\(sinceLastAttemptInMillis)ms, reason=\(metadata.reason)")
        
        return [
            RetryHeaderKeys.rsaRetryAttempt: "\(metadata.attempt)",
            RetryHeaderKeys.rsaSinceLastAttempt: "\(sinceLastAttemptInMillis)",
            RetryHeaderKeys.rsaRetryReason: metadata.reason
        ]
    }
    
    func recordFailure(batchId: String, timestampInMillis: UInt64, error: RetryableEventUploadError) {
        // For the first failure, attempt will be 1. For subsequent failures, it increments by 1.
        let attempt = self.retrieveMetadataForBatch(batchId).map{ $0.attempt + 1 } ?? 1
        let reason = error.retryReason
        
        let newMetadata = RetryMetadata(batchId: batchId, attempt: attempt, lastAttemptTimestampInMillis: timestampInMillis, reason: reason)
        
        guard let json = newMetadata.toJson() else {
            LoggerAnalytics.error("Failed to serialize RetryMetadata to JSON.")
            return
        }
        
        self.storage.write(value: json, key: Constants.storageKeys.retryMetadata)
    }
    
    func clear() {
        LoggerAnalytics.verbose("Clearing retry metadata from storage")
        self.storage.remove(key: Constants.storageKeys.retryMetadata)
    }
}

private extension PrimaryRetryHeadersProvider {
    func retrieveMetadataForBatch(_ batchId: String) -> RetryMetadata? {
        guard let json: String = self.storage.read(key: Constants.storageKeys.retryMetadata), !json.isEmpty else {
            LoggerAnalytics.debug("No retry metadata found in storage.")
            return nil
        }
        
        guard let metadata = RetryMetadata.fromJson(json) else {
            LoggerAnalytics.warn("Failed to parse retry metadata from JSON.")
            return nil
        }
        
        guard metadata.batchId == batchId else {
            LoggerAnalytics.verbose("Discarding stale retry metadata: batchId mismatch")
            return nil
        }
        
        return metadata
    }
}
