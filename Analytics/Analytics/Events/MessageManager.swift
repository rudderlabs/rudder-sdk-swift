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
    var analytics: AnalyticsClient
    
    private var writeChannel: AsyncChannel<Message>
    private var uploader: MessageUploader?
    @Synchronized private var flushedReferences = [String]()
    
    var flushFacade: FlushPolicyFacade?
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.writeChannel = AsyncChannel()
        
        self.uploader = MessageUploader(analytics: analytics)
        self.uploader?.delegate = self
        self.flushFacade = FlushPolicyFacade(analytics: analytics)
        self.start()
    }
    
    deinit {
        self.uploader = nil
        self.stop()
    }
    
    func put(_ message: Message) {
        guard message.type != .flush else { self.flush(); return }
        self.writeChannel.send(message)
    }
    
    private func flush() {
        self.startUploading()
        self.flushFacade?.resetCount()
    }
    
    private func start() {
        self.flushFacade?.startSchedule() //Frequency based flush policy..
        self.shouldFlush() //Startup flush policy
        
        Task {
            await self.writeChannel.consume { message in
                self.performStorage(message)
            }
        }
    }
    
    private func shouldFlush() {
        guard self.flushFacade?.shouldFlush() ?? false else { return }
        self.flush()
    }
    
    func stop() {
        self.writeChannel.closeChannel()
        self.flushFacade?.cancelSchedule()
    }
}

// MARK: - Storage
extension MessageManager {
    var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    func performStorage(_ message: Message) {
        guard let json = message.jsonString else { return }
        self.storage.write(message: json)
        
        self.flushFacade?.updateCount()
        self.shouldFlush()
    }
}

// MARK: - Upload
extension MessageManager {
    var storageMode: StorageMode {
        return self.storage.eventStorageMode
    }
    
    func startUploading() {
        self.storage.rollover {
            let received = self.storage.read().dataItems
            guard !received.isEmpty else { return }
            
            for item in received {
                print(item.batch)
                
                let processed = item.batch.replacingOccurrences(of: Constants.defaultSentAtPlaceholder, with: Date().iso8601TimeStamp)
                
                let uItem = UploadItem(reference: item.reference, content: processed)
                if !self.flushedReferences.contains(item.reference) {
                    self.flushedReferences.append(item.reference)
                    self.uploader?.addToQueue(uItem)
                }
                print("Processed: \(item.reference)")
                print("-------------------------------------------->>>")
            }
        }
    }
}

// MARK: - MessageUploaderDelegate
extension MessageManager: MessageUploaderDelegate {
    func didFinishUploading(item: UploadItem) {
        self.storage.remove(messageReference: item.reference)
    }
    
    func resetReferenceCache(_ pendingUploads: [UploadItem]) {
        pendingUploads.forEach { upload in
            self.flushedReferences.removeAll(where: { $0 == upload.reference }) }
    }
}
