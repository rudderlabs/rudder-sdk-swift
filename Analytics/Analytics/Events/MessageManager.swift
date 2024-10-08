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
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        
        self.start()
    }
    
    deinit {
        self.writeChannel.closeChannel()
        self.uploadChannel.closeChannel()
    }
    
    func put(_ message: Message) {
        guard message.type != .flush else { self.flush(); return }
        self.writeChannel.send(message)
    }
    
    private func flush() {
        self.uploadChannel.send(Constants.uploadSignal)
    }
    
    private func start() {
        Task.detached {
            await self.writeChannel.consume { message in
                self.performStorage(message)
            }
        }
        
        Task.detached {
            await self.uploadChannel.consume { value in
                self.startUploading()
            }
        }
    }
}

// MARK: - Storage
extension MessageManager {
    var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    func performStorage(_ message: Message) {
        Task {
            guard let json = message.toJSONString else { return }
            self.storage.write(message: json)
        }
    }
}

// MARK: - Upload
extension MessageManager {
    func startUploading() {
        // TODO: This section will be completed once the data plane upload implementation is in place.
        self.storage.rollover()
        if let received = self.storage.read().dataItems {
            for item in received {
                print(item.batch)
            }
        }
        
        if let received = self.storage.read().dataFiles {
            for file in received {
                print(file.path())
                print(FileManager.contentsOf(file: file.path()) ?? "No contents of file")
            }
        }
    }
}
