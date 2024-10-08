final class AsyncChannel<T> {
    
    private let channel: AsyncStream<T>
    private var continuation: AsyncStream<T>.Continuation?
    
    // A serial dispatch queue to ensure thread safety
    private let queue = DispatchQueue(label: "com.asyncchannel.serialqueue")
    
    init() {
        var cont: AsyncStream<T>.Continuation?
        channel = AsyncStream { continuation in
            cont = continuation
        }
        continuation = cont
    }
    
    // Add a value to the channel
    func send(value: T) {
        print(Thread.current)
        queue.async { [weak self] in
            self?.continuation?.yield(value)
        }
    }
    
    // Close the channel
    func closeChannel() {
        print(Thread.current)
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
