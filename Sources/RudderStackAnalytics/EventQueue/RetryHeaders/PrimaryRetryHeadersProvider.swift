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
final class PrimaryRetryHeadersProvider: RetryHeadersProvider, TypeIdentifiable {

    private let storage: KeyValueStorage
    private let logger: Logger

    private static let minSinceLastAttemptInMillis: UInt64 = 0
    private static let firstAttempt = 1

    init(storage: KeyValueStorage, logger: Logger) {
        self.storage = storage
        self.logger = logger
    }
    
    func prepareHeaders(batchId: Int, currentTimestampInMillis: UInt64) -> [String: String] {
        guard self.isBatchAvailable(batchId), let metadata = self.retrieveMetadataForBatch(batchId) else { return [:] }
        
        let sinceLastAttemptInMillis: UInt64 = currentTimestampInMillis > metadata.lastAttemptTimestampInMillis
        ? currentTimestampInMillis - metadata.lastAttemptTimestampInMillis
        : Self.minSinceLastAttemptInMillis
        
        logger.verbose(log: "\(className): Adding retry headers: attempt=\(metadata.attempt), sinceLastAttempt=\(sinceLastAttemptInMillis)ms, reason=\(metadata.reason)")
        
        return [
            RetryHeaderKeys.rsaRetryAttempt: "\(metadata.attempt)",
            RetryHeaderKeys.rsaSinceLastAttempt: "\(sinceLastAttemptInMillis)",
            RetryHeaderKeys.rsaRetryReason: metadata.reason
        ]
    }
    
    func recordFailure(batchId: Int, timestampInMillis: UInt64, error: RetryableEventUploadError) {
        guard self.isBatchAvailable(batchId) else { return }
        
        // For the first failure, attempt will be 1. For subsequent failures, it increments by 1.
        let attempt = self.retrieveMetadataForBatch(batchId).map { $0.attempt + 1 } ?? Self.firstAttempt
        let reason = error.retryReason
        
        let newMetadata = RetryMetadata(batchId: batchId, attempt: attempt, lastAttemptTimestampInMillis: timestampInMillis, reason: reason)
        
        guard let json = newMetadata.toJson() else {
            logger.error(log: "\(className): Failed to serialize RetryMetadata to JSON.", error: nil)
            return
        }
        
        self.storage.write(value: json, key: Constants.storageKeys.retryMetadata)
    }
    
    func clear() {
        logger.verbose(log: "\(className): Clearing retry metadata from storage")
        self.storage.remove(key: Constants.storageKeys.retryMetadata)
    }
}

private extension PrimaryRetryHeadersProvider {
    func retrieveMetadataForBatch(_ batchId: Int) -> RetryMetadata? {
        guard let json: String = self.storage.read(key: Constants.storageKeys.retryMetadata), !json.isEmpty else { return nil }
        
        guard let metadata = RetryMetadata.fromJson(json) else {
            logger.warn(log: "\(className): Failed to parse retry metadata from JSON.")
            return nil
        }
        
        guard metadata.batchId == batchId else {
            logger.verbose(log: "\(className): Discarding stale retry metadata: batchId mismatch")
            return nil
        }
        
        return metadata
    }

    func isBatchAvailable(_ batchId: Int) -> Bool {
        return batchId != DataStoreConstants.batchUnavailableId
    }
}
