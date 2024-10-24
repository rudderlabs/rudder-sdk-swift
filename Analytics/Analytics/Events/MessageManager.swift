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
    
    //Different channel for different operations..
    private var writeChannel: AsyncChannel<Message>
    private var uploadChannel: AsyncChannel<String>
    var responseChannel: AsyncChannel<String>
    
    private var uploader: MessageUploader?
    var httpClient: HttpClient?
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        self.responseChannel = AsyncChannel()
        self.httpClient = HttpClient(analytics: analytics)
        
        self.uploader = MessageUploader(manager: self)
        
        self.start()
    }
    
    deinit {
        self.httpClient = nil
        self.uploader = nil
        self.stop()
    }
    
    func put(_ message: Message) {
        guard message.type != .flush else { self.flush(); return }
        self.writeChannel.send(message)
    }
    
    private func flush() {
        self.uploadChannel.send(Constants.uploadSignal)
    }
    
    private func start() {
        Task {
            await self.writeChannel.consume { message in
                self.performStorage(message)
            }
        }
        
        Task {
            await self.uploadChannel.consume { value in
                self.startUploading()
            }
        }
        
        Task {
            await self.responseChannel.consume { value in
                self.storage.remove(messageReference: value)
            }
        }
    }
    
    func stop() {
        self.writeChannel.closeChannel()
        self.uploadChannel.closeChannel()
        self.responseChannel.closeChannel()
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
    }
}

// MARK: - Upload
extension MessageManager {
    var storageMode: StorageMode {
        return self.storage.eventStorageMode
    }
    
    func startUploading() {
        self.storage.rollover {
            if self.storageMode == .disk {
                if let received = self.storage.read().dataFiles { // disk store
                    received.forEach {
                        if let content = FileManager.contentsOf(file: $0.path()) {
                            print(content)
                            let item = UploadItem(content: content, reference: $0.path())
                            self.uploader?.addToQueue(item)
                            print("Processed: \($0.path())")
                            print("-------------------------------------------->>>")
                        }
                    }
                }
            } else {
                if let received = self.storage.read().dataItems { // memory store
                    received.forEach {
                        print($0.batch)
                        let item = UploadItem(content: $0.batch, reference: $0.id)
                        self.uploader?.addToQueue(item)
                        print("Processed: \($0.id)")
                        print("-------------------------------------------->>>")
                    }
                }
            }
        }
    }
}
