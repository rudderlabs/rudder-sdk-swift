//
//  NetworkInfoPluginUtils.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/12/24.
//

import Foundation
import Network

/**
 A utility class for retrieving network connectivity information.
 */
final class NetworkInfoPluginUtils: NSObject {
    var networkMonitor: NetworkMonitorProtocol
    
    init(monitor: NetworkMonitorProtocol = NetworkMonitor()) {
        self.networkMonitor = monitor
        super.init()
    }
}

// MARK: - Network Connectivity
extension NetworkInfoPluginUtils {
    func checkNetworkConnectivity() -> (cellular: Bool, wifi: Bool) {
        var cellular = false
        var wifi = false
        
        let path = self.networkMonitor
        wifi = path.usesInterfaceType(.wifi)
        
        #if os(iOS) || os(macOS) || os(watchOS)
            cellular = path.usesInterfaceType(.cellular)
        #else
            cellular = false
        #endif
        
        return (cellular, wifi)
    }
}

// MARK: - NetworkMonitorProtocol
/**
 A protocol defining the interface for monitoring network connectivity.
 */
protocol NetworkMonitorProtocol {
    var status: NWPath.Status { get }
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool
    func start(queue: DispatchQueue)
    func cancel()
}

// MARK: - NetworkMonitor
/**
 This class monitors the network connectivity status and interfaces using the Network framework.
 */
class NetworkMonitor: NetworkMonitorProtocol {
    private let monitor = NWPathMonitor()

    init() {
        let semaphore = DispatchSemaphore(value: 0)
        monitor.pathUpdateHandler = { _ in
            semaphore.signal()
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        semaphore.wait()
    }

    var status: NWPath.Status {
        return monitor.currentPath.status
    }

    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        return monitor.currentPath.usesInterfaceType(type)
    }
    
    func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }

    func cancel() {
        monitor.cancel()
    }
}
