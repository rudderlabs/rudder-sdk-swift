//
//  NetworkInfoPluginUtils.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/12/24.
//

import Foundation
import CoreBluetooth
import Network

/**
 A utility class for retrieving Bluetooth and network connectivity information.
 */
final class NetworkInfoPluginUtils: NSObject {
    var isBluetoothEnabled = false
    var isBluetoothInitialized: Bool = false
    var bluetoothManager: CBCentralManager?
    var networkMonitor: NetworkMonitorProtocol
    
    init(monitor: NetworkMonitorProtocol = NetworkMonitor()) {
        self.networkMonitor = monitor
        super.init()
        self.initializeBluetooth()
    }
}

// MARK: - Bluetooth
extension NetworkInfoPluginUtils: CBCentralManagerDelegate {
    
    var canInitializeBluetooth: Bool {
        #if os(iOS) || os(watchOS) || os(visionOS)
            let permissionKey = "NSBluetoothAlwaysUsageDescription"
        #elseif os(macOS)
            let permissionKey = "NSBluetoothPeripheralUsageDescription"
        #else
            return false
        #endif

        guard Bundle.main.object(forInfoDictionaryKey: permissionKey) != nil else {
            print("\(permissionKey) is missing. Skipping Bluetooth initialization.")
            return false
        }
        return true
    }
    
    var isBluetoothAvailable: Bool {
        return self.isBluetoothInitialized && CBManager.authorization == .allowedAlways
    }
    
    func initializeBluetooth() {
        guard self.canInitializeBluetooth else { return }
        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        self.isBluetoothInitialized = true
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.isBluetoothEnabled = central.state == .poweredOn
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
    private let semaphore = DispatchSemaphore(value: 0)
    private var path: NWPath?
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.path = path
            self?.semaphore.signal()
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        semaphore.wait()
    }
    
    var status: NWPath.Status {
        return path?.status ?? .unsatisfied
    }
    
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        return path?.usesInterfaceType(type) ?? false
    }
    
    func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }
    
    func cancel() {
        monitor.cancel()
    }
}
