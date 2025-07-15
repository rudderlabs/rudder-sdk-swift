//
//  AsyncChannel.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation

// MARK: - AsyncChannel
/**
 A thread-safe asynchronous channel for sending and receiving values.
 
 This class provides a simple way to send values from one part of your code and receive them
 asynchronously in another part using Swift's AsyncStream.
 */

final class AsyncChannel<Element> {
    private var continuation: AsyncStream<Element>.Continuation?
    private let stream: AsyncStream<Element>
    private let lock = NSLock()
    
    /**
     Indicates whether the channel is closed.
     */
    var isClosed = false
    
    /**
     Creates a new async channel.
     */
    init() {
        var continuationLocal: AsyncStream<Element>.Continuation!
        
        self.stream = AsyncStream<Element>(bufferingPolicy: .unbounded) { continuation in
            continuationLocal = continuation
        }
        
        self.continuation = continuationLocal
    }
    
    /**
     Sends a value to the channel.
     
     - Parameter value: The value to send.
     - Throws: `ChannelError.closed` if the channel is closed.
     */
    func send(_ value: Element) throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isClosed else {
            throw ChannelError.closed
        }
        
        continuation?.yield(value)
    }
    
    /**
     Returns an async stream to receive values from the channel.
     
     - Returns: An `AsyncStream` that yields values sent to the channel.
     */
    func receive() -> AsyncStream<Element> {
        return stream
    }
    
    /**
     Closes the channel. No more values can be sent after calling this method.
     */
    func close() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isClosed else { return }
        isClosed = true
        continuation?.finish()
        continuation = nil
    }
    
    /**
     Sets a handler to be called when the channel terminates.
     
     - Parameter completion: The closure to call when the channel terminates.
     */
    func setTerminationHandler(_ completion: (() -> Void)?) {
        continuation?.onTermination = { @Sendable _ in
            completion?()
        }
    }
    
    /**
     Errors that can occur when working with the channel.
     */
    enum ChannelError: Error {
        case closed
        
        var localizedDescription: String {
            switch self {
            case .closed:
                return "Channel is closed"
            }
        }
    }
}
