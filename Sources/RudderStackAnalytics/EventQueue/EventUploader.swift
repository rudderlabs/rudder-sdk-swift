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
                        await self.storage.remove(eventReference: item.reference)
                        continue
                    }
                    
                    LoggerAnalytics.debug(log: "Upload started: \(item.reference)")
                    do {
                        // Process the batch by replacing timestamp placeholder with current time
                        let processed = batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
                        LoggerAnalytics.debug(log: "Uploading (processed): \(processed)")
                        
                        // Send the batch to the data plane
                        let responseData = try await self.httpClient.postBatchEvents(processed)
                        LoggerAnalytics.debug(log: "Upload response: \(responseData.jsonString ?? "No response")")
                        
                        // Remove successfully uploaded batch from storage
                        await self.storage.remove(eventReference: item.reference)
                        LoggerAnalytics.debug(log: "Upload completed: \(item.reference)")
                    } catch {
                        LoggerAnalytics.error(log: "Upload failed: \(item.reference)", error: error)
                    }
                }
            }
        }
    }
    
    func stop() {
        guard !self.uploadChannel.isClosed else { return }
        self.uploadChannel.close()
    }
}
