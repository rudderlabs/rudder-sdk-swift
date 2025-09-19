//
//  Connectivity.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 18/09/25.
//

import Network
import Combine

/**
 Class to monitor network connectivity status using NWPathMonitor. Provides a publisher to observe connectivity changes.
*/
final class Connectivity {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "ConnectivityMonitor")
    private let subject: CurrentValueSubject<Bool, Never>
    private var isMonitoring = false
    
    // Publisher to observe connectivity changes
    var connectivityState: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }
    
    // Current connectivity status (synchronous access)
    var isConnected: Bool {
        subject.value
    }
    
    init() {
        monitor = NWPathMonitor()
        subject = CurrentValueSubject(false) // default: offline
        
        // Set up the path update handler
        monitor.pathUpdateHandler = { [weak self] path in
            self?.subject.send(path.status == .satisfied)
        }

        startMonitoring()
    }
    
    /// Starts monitoring network connectivity
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
    }

    deinit {
        stopMonitoring()
    }
}
