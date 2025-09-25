//
//  EventUploader.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/25.
//

import Foundation

// MARK: - EventUploader
/**
 EventUploader is responsible for uploading analytics events to the RudderStack data plane.
 */
final class EventUploader {
    private let analytics: Analytics
    private let httpClient: HttpClient
    private let uploadChannel: AsyncChannel<String>
    private let backoff: BackoffPolicyHandler
    private var lastBatchAnonymousId: String = ""
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: Analytics, uploadChannel: AsyncChannel<String>) {
        self.analytics = analytics
        self.httpClient = HttpClient(analytics: analytics)
        self.uploadChannel = uploadChannel
        self.backoff = BackoffPolicyHandler()
    }
    
    func start() {
        Task { [weak self] in
            guard let self else { return }
            
            for await _ in self.uploadChannel.receive() {
                
                // Read all available batched events from storage
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    // Check shutdown conditions before processing each item
                    if self.analytics.isAnalyticsShutdown { break }
                    
                    // Read the event batch from storage
                    let batch = self.analytics.storage.eventStorageMode == .memory ? item.batch : (FileManager.contentsOf(file: item.reference) ?? .empty)
                    guard !batch.isEmpty else {
                        LoggerAnalytics.debug("No batch found for reference: \(item.reference)")
                        
                        // Remove empty batch from storage
                        await self.deleteBatchFile(item.reference)
                        continue
                    }
                    
                    // Update anonymousId header if needed
                    self.updateAnonymousIdHeaderIfNeeded(batch)
                    
                    // Upload the batch
                    await self.uploadBatch(batch, reference: item.reference)
                }
            }
        }
    }
    
    func stop() {
        guard !self.uploadChannel.isClosed else { return }
        self.uploadChannel.close()
    }
}

// MARK: - Batch Upload
extension EventUploader {
    private func uploadBatch(_ batch: String, reference: String) async {
        var shouldRetry = false
        repeat {
            LoggerAnalytics.debug("Upload started: \(reference)")
            // Process the batch by replacing timestamp placeholder with current time
            let processed = batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
            LoggerAnalytics.debug("Uploading (processed): \(processed)")
            
            // Send the batch to the data plane
            let responseResult = await self.httpClient.postBatchEvents(processed)
            
            // Handle the response and determine if retry is needed
            switch responseResult {
            case .success(let data):
                LoggerAnalytics.debug("Upload response: \(data.jsonString ?? "No response")")
                await self.handleBatchUploadResponse(data, reference: reference)
                shouldRetry = false
            
            case .failure(let error):
                await self.handleBatchUploadFailure(error, reference: reference)
                shouldRetry = error is RetryableEventUploadError
            }
        } while shouldRetry
    }
    
    private func handleBatchUploadResponse(_ data: Data, reference: String) async {
        // Remove successfully uploaded batch from storage
        await self.backoff.reset()
        await self.deleteBatchFile(reference)
        LoggerAnalytics.debug("Upload completed: \(reference)")
    }
    
    private func handleBatchUploadFailure(_ error: EventUploadError, reference: String) async {
        LoggerAnalytics.error(log: "Upload failed: \(reference)", error: error)
        
        // Handle non-retryable errors
        if let nonRetryableError = error as? NonRetryableEventUploadError {
            await self.backoff.reset()
            await self.handleNonRetryableError(nonRetryableError, reference: reference)
        }
        
        // Apply backoff for retryable errors
        if error is RetryableEventUploadError {
            await self.backoff.waitWithBackoff()
        }
    }
}

// MARK: - Error Handlers
extension EventUploader: TypeIdentifiable {
    private func handleNonRetryableError(_ error: NonRetryableEventUploadError, reference: String) async {
        switch error {
        case .error400:
            LoggerAnalytics.error(log: "\(className): \(error.formatStatusCodeMessage). Invalid request: Missing or malformed body. " + "Ensure the payload is a valid JSON and includes either 'anonymousId' or 'userId' properties.")
            await self.deleteBatchFile(reference)
          
        case .error401:
            LoggerAnalytics.error(log: "\(className): \(error.formatStatusCodeMessage). " + "Invalid write key. Ensure the write key is valid.")
            self.stop()
            self.analytics.handleInvalidWriteKey()
            
        case .error404:
            LoggerAnalytics.error(log: "\(className): \(error.formatStatusCodeMessage). " + "Stopping the events upload process until the source is enabled again.")
            self.stop()
            self.analytics.sourceConfigState.dispatch(action: DisableSourceConfigAction())

        case .error413:
            LoggerAnalytics.error(log: "\(className): \(error.formatStatusCodeMessage). " + "Request failed: Payload size exceeds the maximum allowed limit.")
            await self.deleteBatchFile(reference)
        }
    }
}

// MARK: - Helpers
extension EventUploader {
    private func deleteBatchFile(_ reference: String) async {
        await self.storage.remove(batchReference: reference)
    }

    private func updateAnonymousIdHeaderIfNeeded(_ batch: String) {
        guard let anonymousId = self.extractAnonymousIdFromBatch(batch) else {
            return // No anonymousId found, don't update header
        }

        if anonymousId != lastBatchAnonymousId {
            self.httpClient.updateAnonymousIdHeader(anonymousId)
            self.lastBatchAnonymousId = anonymousId
        }
    }

    func extractAnonymousIdFromBatch(_ batch: String) -> String? {
        do {
            let anonymousIdRegex = try NSRegularExpression(pattern: "\"anonymousId\"\\s*:\\s*\"([^\"]+)\"")
            let range = NSRange(location: 0, length: batch.utf16.count)

            guard let match = anonymousIdRegex.firstMatch(in: batch, options: [], range: range),
                  let anonymousIdRange = Range(match.range(at: 1), in: batch) else {
                return nil
            }

            return String(batch[anonymousIdRange])
        } catch {
            LoggerAnalytics.error(log: "Failed to create regex for anonymousId extraction: \(error)")
            return nil
        }
    }
}
