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
    private var httpClient: HttpClient?
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        self.httpClient = HttpClient(analytics: analytics)
        
        self.start()
    }
    
    deinit {
        self.httpClient = nil
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
    }
    
    func stop() {
        self.writeChannel.closeChannel()
        self.uploadChannel.closeChannel()
    }
}

// MARK: - Storage
extension MessageManager {
    var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    func performStorage(_ message: Message) {
        Task {
            guard let json = message.jsonString else { return }
            await self.storage.write(message: json)
        }
    }
}

// MARK: - Upload
extension MessageManager {
    
    var storageMode: StorageMode {
        return self.storage.eventStorageMode
    }
    
    func startUploading() {
        Task {
            await self.storage.rollover()
            
            if self.storageMode == .disk {
                if let received = self.storage.read().dataFiles { // disk store
                    for file in received {
                        print(file.path())
                        print(FileManager.contentsOf(file: file.path()) ?? "No contents of file")
                        
                        guard let content = FileManager.contentsOf(file: file.path()) else { continue }
                        await self.uploadBatch(content, file.path())
                        print("Processed: \(file.path())")
                    }
                }
            } else {
                if let received = self.storage.read().dataItems { // memory store
                    for item in received {
                        print(item.batch)
                        await self.uploadBatch(item.batch, item.id)
                        print("Processed: \(item.id)")
                    }
                }
            }
            
        }
    }
    
    func uploadBatch(_ batch: String, _ reference: String) async {
        self.httpClient?.postBatchEvents(batch, { result in
            switch result {
            case .success(let response):
                print(response.jsonString ?? "Bad response")
                self.storage.remove(messageReference: reference)
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
}
