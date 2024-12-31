//
//  MessageManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation
// MARK: - MessageManager
/**
 A class responsible for managing messages and handling their processing, storage, and uploading in the analytics system.

 This class integrates with the analytics client, manages flush policies, and ensures smooth message flow using asynchronous channels.
 */
final class MessageManager {
    
    /// The analytics client instance used for configuration and message handling.
    private let analytics: AnalyticsClient
    
    /// Manages flush policies for controlling message uploads.
    private let flushPolicyFacade: FlushPolicyFacade
    
    /// Handles HTTP requests for uploading messages.
    private let httpClient: HttpClient
    
    /// An event that signals when a flush operation should occur.
    private let flushEvent = FlushEvent(messageName: Constants.uploadSignal)
    
    /// An asynchronous channel for writing messages.
    private let writeChannel: AsyncChannel<Message>
    
    /// An asynchronous channel for uploading messages.
    private let uploadChannel: AsyncChannel<String>
    
    /// The storage system for persisting messages.
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    /**
     Initializes the `MessageManager` with the provided analytics client.

     - Parameter analytics: The `AnalyticsClient` instance responsible for managing the analytics lifecycle.
     */
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        self.httpClient = HttpClient(analytics: analytics)
        self.writeChannel = AsyncChannel(capacity: Int.max)
        self.uploadChannel = AsyncChannel(capacity: Int.max)
        self.start()
    }
    
    /**
     Cleans up resources and stops any ongoing tasks when the instance is deinitialized.
     */
    deinit {
        self.stop()
    }
}

// MARK: - Operations
extension MessageManager {
    /**
     Starts the message manager by scheduling flush policies and initializing message processing.
     */
    private func start() {
        self.flushPolicyFacade.startSchedule()
        self.write()
        self.upload()
    }
    
    /**
     Adds a message to the write channel for processing.

     - Parameter message: The message to be added to the processing queue.
     */
    func put(_ message: Message) {
        Task {
            try await self.writeChannel.send(message)
        }
    }
    
    /**
     Triggers a manual flush operation, signaling the system to process and upload messages.
     */
    func flush() {
        print("Flush triggered...")
        Task {
            try await self.writeChannel.send(self.flushEvent)
        }
    }
    
    /**
     Stops the message manager, cancels scheduled tasks, and closes all channels.
     */
    func stop() {
        self.flushPolicyFacade.cancelSchedule()
        self.writeChannel.close()
        self.uploadChannel.close()
    }
}

// MARK: - Message Processing
extension MessageManager {
    /**
     Continuously processes messages from the write channel and stores or signals them for upload.
     */
    func write() {
        Task {
            for await message in self.writeChannel.stream {
                let isFlushSignal = message.type == .flush

                if !isFlushSignal {
                    if let json = message.jsonString {
                        await self.storage.write(message: json)
                        self.flushPolicyFacade.updateCount()
                    }
                }

                if isFlushSignal || self.flushPolicyFacade.shouldFlush() {
                    do {
                        self.flushPolicyFacade.resetCount()
                        await self.storage.rollover()
                        try await self.uploadChannel.send(Constants.uploadSignal)
                    } catch {
                        print("Error on upload signal: \(error)")
                    }
                }
            }
        }
    }
    
    /**
     Continuously reads upload signals from the upload channel and processes message uploads.

     This method reads batched messages from storage and uploads them to the server. Successful uploads are removed from storage.
     */
    func upload() {
        Task {
            for await _ in self.uploadChannel.stream {
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    print("Upload started: \(item.reference)")
                    do {
                        let processed = item.batch.replacingOccurrences(of: Constants.defaultSentAtPlaceholder, with: Date().iso8601TimeStamp)
                        print("Uploading: \(processed)")
                        
                        _ = try await self.httpClient.postBatchEvents(processed)
                        
                        await self.storage.remove(messageReference: item.reference)
                        print("Upload completed: \(item.reference)")
                    } catch {
                        print("Upload failed: \(item.reference)")
                    }
                }
            }
        }
    }
}
