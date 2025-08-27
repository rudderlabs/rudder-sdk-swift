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
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: Analytics, uploadChannel: AsyncChannel<String>) {
        self.analytics = analytics
        self.httpClient = HttpClient(analytics: analytics)
        self.uploadChannel = uploadChannel
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
                        LoggerAnalytics.debug(log: "No batch found for reference: \(item.reference)")
                        
                        // Remove empty batch from storage
                        await self.deleteBatchFile(item.reference)
                        continue
                    }
                    
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
extension EventUploader: TypeIdentifiable {
    
    private func uploadBatch(_ batch: String, reference: String) async {
        LoggerAnalytics.debug(log: "Upload started: \(reference)")
        
        // Process the batch by replacing timestamp placeholder with current time
        let processed = batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
        LoggerAnalytics.debug(log: "Uploading (processed): \(processed)")
        
        // Send the batch to the data plane
        let responseResult = await self.httpClient.postBatchEvents(processed)
        
        // Handle the response
        switch responseResult {
        case .success(let data):
            LoggerAnalytics.debug(log: "Upload response: \(data.jsonString ?? "No response")")
            await self.handleBatchUploadResponse(data, reference: reference)
        case .failure(let error):
            await self.handleBatchUploadFailure(error, reference: reference)
        }
    }
    
    private func handleBatchUploadResponse(_ data: Data, reference: String) async {
        // Remove successfully uploaded batch from storage
        await self.deleteBatchFile(reference)
        LoggerAnalytics.debug(log: "Upload completed: \(reference)")
    }
    
    private func handleBatchUploadFailure(_ error: EventUploadError, reference: String) async {
        LoggerAnalytics.error(log: "Upload failed: \(reference)", error: error)
        
        // TODO: - Handle batch upload errors (use below tickets)
        // https://linear.app/rudderstack/issue/SDK-3724/handle-status-code-401-from-batch-upload-request
        // https://linear.app/rudderstack/issue/SDK-3722/handle-status-code-404-from-batch-upload-request
        // https://linear.app/rudderstack/issue/SDK-3726/introduce-retry-logic-in-batch-upload-flow
        
        if let nonRetryableError = error as? NonRetryableEventUploadError {
            switch nonRetryableError {
            case .error400, .error413:
                if nonRetryableError == .error400 {
                    LoggerAnalytics.error(log: "\(className): \(nonRetryableError.formatStatusCodeMessage). Invalid request: Missing or malformed body. " + "Ensure the payload is a valid JSON and includes either 'anonymousId' or 'userId' properties")
                } else {
                    LoggerAnalytics.error(log: "\(className): \(nonRetryableError.formatStatusCodeMessage). " + "Request failed: Payload size exceeds the maximum allowed limit.")
                }
                await self.deleteBatchFile(reference)
            default:
                break
            }
        }
    }
}

// MARK: - Helpers
extension EventUploader {
    private func deleteBatchFile(_ reference: String) async {
        await self.storage.remove(eventReference: reference)
    }
}
