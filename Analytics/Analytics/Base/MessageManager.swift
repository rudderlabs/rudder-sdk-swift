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
    
    private let analytics: AnalyticsClient
    private let flushPolicyFacade: FlushPolicyFacade
    private let httpClient: HttpClient
    private let flushEvent = FlushEvent(messageName: Constants.uploadSignal)
    private let writeChannel: AsyncChannel<Message>
    private let uploadChannel: AsyncChannel<String>
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        self.httpClient = HttpClient(analytics: analytics)
        self.writeChannel = AsyncChannel(capacity: Int.max)
        self.uploadChannel = AsyncChannel(capacity: Int.max)
        self.start()
    }
    
    deinit {
        self.stop()
    }
}

// MARK: - Operations
extension MessageManager {
    
    private func start() {
        self.flushPolicyFacade.startSchedule()
        self.write()
        self.upload()
    }
    
    func put(_ message: Message) {
        Task {
            try await self.writeChannel.send(message)
        }
    }
    
    func flush() {
        print("Flush triggered...")
        Task {
            try await self.writeChannel.send(self.flushEvent)
        }
    }
    
    func stop() {
        self.flushPolicyFacade.cancelSchedule()
        self.writeChannel.close()
        self.uploadChannel.close()
    }
}

// MARK: - Message Processing
extension MessageManager {
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
