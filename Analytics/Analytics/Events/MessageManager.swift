//
//  MessageManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation
// MARK: - MessageManager
/**
 This class manages messages and their operations, such as storing and uploading them.
 */
final class MessageManager {
    private let analytics: AnalyticsClient
    private let flushPolicyFacade: FlushPolicyFacade
    private let httpClient: HttpClient
    private let messageChannel: AsyncChannel<Message>
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        self.httpClient = HttpClient(analytics: analytics)
        self.messageChannel = AsyncChannel()
        
        self.start()
    }
    
    deinit {
        self.stop()
    }
}

// MARK: - Operations
extension MessageManager {
    
    private func start() {
        self.flushPolicyFacade.startSchedule() //Frequency based flush policy..
        self.startProcessingMessage()
        
        if self.flushPolicyFacade.shouldFlush() {
            self.flush() //Startup flush policy
        }
    }
    
    func put(_ message: Message) {
        self.messageChannel.send(message)
    }
    
    func flush() {
        print("Flush triggered...")
        self.messageChannel.send(FlushEvent(messageName: Constants.uploadSignal))
    }
    
    func stop() {
        self.messageChannel.closeChannel()
        self.flushPolicyFacade.cancelSchedule()
    }
}

// MARK: - Storage
extension MessageManager {
    func startProcessingMessage() {
        Task {
            await self.messageChannel.consume { message in
                let isFlushSignal = message.type == .flush

                if !isFlushSignal {
                    if let json = message.jsonString {
                        await self.storage.write(message: json)
                        self.flushPolicyFacade.updateCount()
                    }
                }
                
                if isFlushSignal || self.flushPolicyFacade.shouldFlush() {
                    await self.storage.rollover()
                    
                    let dataItems = await self.storage.read().dataItems
                    for item in dataItems {
                        print("Upload started: \(item.reference)")
                        let isUploaded = await self.upload(item: item)
                        
                        if isUploaded {
                            await self.storage.remove(messageReference: item.reference)
                            print("Upload completed: \(item.reference)")
                        } else {
                            print("Upload failed: \(item.reference)")
                        }
                    }
                    self.flushPolicyFacade.resetCount()
                }
            }
        }
    }
    
    private func upload(item: MessageDataItem) async -> Bool {
        do {
            let processed = item.batch.replacingOccurrences(of: Constants.defaultSentAtPlaceholder, with: Date().iso8601TimeStamp)
            print("Uploading: \(processed)")
            _ = try await self.httpClient.postBatchEvents(processed)
            return true
        } catch {
            return false
        }
    }
}
