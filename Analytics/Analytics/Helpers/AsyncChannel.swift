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
    private let bufferCapacity: Int
    private var buffer: [T] = []
    private var isClosed = false
    private let lock = NSLock()

    init(capacity: Int = 0) {
        precondition(capacity >= 0, "Capacity must be non-negative")
        self.bufferCapacity = capacity
        
        var continuation: AsyncStream<T>.Continuation!
        let stream = AsyncStream<T> { cont in
            continuation = cont
        }
        self.continuation = continuation
        self.stream = stream
    }
    
    /// The async sequence to receive elements.
    let stream: AsyncStream<T>

    /// Sends an element to the channel.
    func send(_ element: T) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            lock.lock()
            defer { lock.unlock() }
            
            guard !isClosed else {
                cont.resume(throwing: ChannelError.closed)
                return
            }

            if bufferCapacity == 0 || buffer.count < bufferCapacity {
                buffer.append(element)
                continuation.yield(element)
                cont.resume()
            } else {
                Task.detached {
                    await self.waitUntilSpaceAvailable()
                    try await self.send(element)
                    cont.resume()
                }
            }
        }
    }

    /// Closes the channel, signaling no more sends.
    func close() {
        lock.lock()
        defer { lock.unlock() }
        
        isClosed = true
        continuation.finish()
    }

    /// Cancels the channel immediately, discarding pending data.
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.removeAll()   // Clear pending data
        isClosed = true
        continuation.finish() // Stops the stream immediately
    }
    
    /// A helper to wait for space in the buffer.
    private func waitUntilSpaceAvailable() async {
        await withCheckedContinuation { cont in
            lock.lock()
            defer { lock.unlock() }
            if buffer.count < bufferCapacity {
                cont.resume()
            } else {
                let delay = 0.01
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    cont.resume()
                }
            }
        }
    }
}

/// Errors that can occur when using the channel.
enum ChannelError: Error {
    case closed
}
