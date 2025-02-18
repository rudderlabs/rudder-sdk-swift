//
//  PermissionManager.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 16/02/25.
//

import Foundation
import CoreBluetooth
import AppTrackingTransparency
import AdSupport

enum PermissionType {
    case idfa
    case bluetooth
}

final class PermissionManager: NSObject {
    private var permissionQueue: [PermissionType] = []
    private var completion: (() -> Void)?
    private var centralManager: CBCentralManager?
    private var bluetoothCompletion: (() -> Void)?

    func requestPermissions(_ permissions: [PermissionType], completion: @escaping () -> Void) {
        permissionQueue = permissions
        self.completion = completion
        requestNextPermission()
    }
    
    private func requestNextPermission() {
        guard let nextPermission = permissionQueue.first else {
            completion?()
            return
        }
        
        permissionQueue.removeFirst()
        
        switch nextPermission {
        case .idfa:
            requestIDFAPermission(completion: requestNextPermission)
        case .bluetooth:
            requestBluetoothPermission(completion: requestNextPermission)
        }
    }
    
    
}
// MARK: - IDFA
extension PermissionManager {
    private func requestIDFAPermission(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            ATTrackingManager.requestTrackingAuthorization { status in
                print("IDFA Status: \(status.rawValue)")
                if status == .authorized {
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    print("IDFA: \(idfa)")
                }
                completion()
            }
        }
    }
}

// MARK: - Bluetooth
extension PermissionManager: CBCentralManagerDelegate {
    
    private func requestBluetoothPermission(completion: @escaping () -> Void) {
        bluetoothCompletion = completion
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is On")
        case .poweredOff:
            print("Bluetooth is Off")
        default:
            print("Bluetooth state: \(central.state.rawValue)")
        }
        // Trigger completion only after user interaction with Bluetooth alert
        bluetoothCompletion?()
        bluetoothCompletion = nil
    }
}
