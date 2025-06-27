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

final class AsyncChannel<T> {
    private let continuation: AsyncStream<T>.Continuation
    private var isClosed = false
    private let lock = NSLock()
    
    init(capacity: Int = .max) {
        var continuation: AsyncStream<T>.Continuation!
        
        let stream = AsyncStream<T>(bufferingPolicy: .bufferingOldest(capacity)) { cont in
            continuation = cont
        }
        self.continuation = continuation
        self.stream = stream
    }
    
    let stream: AsyncStream<T>
    
    func send(_ element: T) async throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isClosed else {
            throw ChannelError.closed
        }
        
        continuation.yield(element)
    }
    
    func close() {
        lock.lock()
        defer { lock.unlock() }
        
        isClosed = true
        continuation.finish()
    }
    
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        isClosed = true
        continuation.finish()
    }
}

enum ChannelError: Error {
    case closed
}
