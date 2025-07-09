//
//  AsyncChannel.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation

// MARK: - AsyncChannel
/**
 This class utilizes `AsyncStream` to implement a subscription pattern.
 */

actor AsyncChannel<T> {
    private let continuation: AsyncStream<T>.Continuation
    private var isClosed = false
    nonisolated private let streamInternal: AsyncStream<T>

    init() {
        var tempContinuation: AsyncStream<T>.Continuation!

        let stream = AsyncStream<T>(bufferingPolicy: .unbounded) { cont in
            tempContinuation = cont
        }

        self.continuation = tempContinuation
        self.streamInternal = stream
    }

    nonisolated var stream: AsyncStream<T> {
        return streamInternal
    }

    func send(_ element: T) throws {
        guard !isClosed else {
            throw ChannelError.closed
        }
        
        continuation.yield(element)
    }

    private func closeChannel() {
        guard !isClosed else { return }
        isClosed = true
        continuation.finish()
    }
    
    nonisolated func close() {
        Task {
            await self.closeChannel()
        }
    }
    
    /// Check if the channel is closed from outside
    nonisolated func isChannelClosed() async -> Bool {
        await self.isClosed
    }
}

enum ChannelError: Error {
    case closed
    
    var localizedDescription: String {
        switch self {
        case .closed:
            return "Channel is closed"
        }
    }
}
