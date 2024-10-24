//
//  AsyncChannel.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

// MARK: - AsyncChannel
/**
 This class utilizes `AsyncStream` to implement a subscription pattern, along with a dedicated serial queue.
 */
final class AsyncChannel<T> {
    private let channel: AsyncStream<T>
    private var continuation: AsyncStream<T>.Continuation?
    
    // A serial dispatch queue to ensure thread safety
    private let queue = DispatchQueue(label: "rudderstack.message.async.queue")
    
    init() {
        var cont: AsyncStream<T>.Continuation?
        channel = AsyncStream { continuation in
            cont = continuation
        }
        continuation = cont
    }
    
    // Add a value to the channel
    func send(_ value: T) {
        queue.async { [weak self] in
            self?.continuation?.yield(value)
        }
    }
    
    // Close the channel
    func closeChannel() {
        queue.async { [weak self] in
            self?.continuation?.finish()
        }
    }
    
    // Consume the stream with a block
    func consume(_ block: @escaping (T) -> Void) async {
        for await value in channel {
            block(value)
        }
    }
}
