//
//  EventUploader.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 16/07/25.
//

import Foundation

// MARK: - EventUploader
final class EventUploader {
    private let analytics: Analytics
    private let httpClient: HttpClient
    private let uploadChannel: AsyncChannel<String>
    
    private var uploadEventTask: Task<Void, Never>?
    private var isShuttingDown = false
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: Analytics, uploadChannel: AsyncChannel<String>) {
        self.analytics = analytics
        self.httpClient = HttpClient(analytics: analytics)
        self.uploadChannel = uploadChannel
    }
    
    func start() {
        self.upload()
    }
    
    func stop() {
        // Guard against multiple shutdown calls
        guard !isShuttingDown else { return }
        isShuttingDown = true
        
        // Wait for upload task to complete naturally
        // This allows ongoing uploads to finish
        if let task = self.uploadEventTask {
            task.waitForCompletion()
        }
    }
    
    private func upload() {
        
        self.uploadChannel.setTerminationHandler { [weak self] in
            // Just clean up the task reference when channel terminates
            self?.uploadEventTask = nil
        }
        
        self.uploadEventTask = Task { [weak self] in
            guard let self else { return }
                        
            for await _ in self.uploadChannel.receive() {
                // If shutdown is initiated, don't start new upload cycles
                if self.isShuttingDown { break }
                
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    // Check shutdown conditions
                    if self.analytics.isAnalyticsShutdown || self.isShuttingDown {
                        break
                    }
                    
                    LoggerAnalytics.debug(log: "Upload started: \(item.reference)")
                    do {
                        let processed = item.batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
                        LoggerAnalytics.debug(log: "Uploading (processed): \(processed)")
                        
                        let responseData = try await self.httpClient.postBatchEvents(processed)
                        LoggerAnalytics.debug(log: "Upload response: \(responseData.jsonString ?? "No response")")
                        
                        await self.storage.remove(eventReference: item.reference)
                        LoggerAnalytics.debug(log: "Upload completed: \(item.reference)")
                    } catch {
                        LoggerAnalytics.error(log: "Upload failed: \(item.reference)", error: error)
                    }
                }
            }
        }
    }
}
