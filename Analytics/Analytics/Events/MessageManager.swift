//
//  MessageManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation

final class MessageManager {
    var analytics: AnalyticsClient
    
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
    
    func flush() {
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

extension MessageManager {
    func startUploading() {
        // TODO: will work....
    }
}
