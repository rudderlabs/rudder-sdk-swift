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
import RudderStackAnalytics
import UIKit

enum PermissionType {
    case idfa
    case bluetooth
    case pushNotification
}

final class PermissionManager: NSObject {
    private var permissionQueue: [PermissionType] = []
    private var completion: (() -> Void)?
    private var centralManager: CBCentralManager?
    private var bluetoothCompletion: (() -> Void)?
    private var pushNotificationCompletion: (() -> Void)?

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
        case .pushNotification:
            requestPushNotificationPermission(completion: requestNextPermission)
        }
    }
}

// MARK: - APNS
extension PermissionManager {
    private func requestPushNotificationPermission(completion: @escaping () -> Void) {
        pushNotificationCompletion = completion
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    // If not granted, finish immediately
                    self.pushNotificationCompletion?()
                    self.pushNotificationCompletion = nil
                }
            }
        }
    }

    // Call this from AppDelegate when device token is received
    func didRegisterForRemoteNotifications() {
        pushNotificationCompletion?()
        pushNotificationCompletion = nil
    }
}

// MARK: - IDFA
extension PermissionManager {
    private func requestIDFAPermission(completion: @escaping () -> Void) {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            NotificationCenter.default.addObserver(self, selector: #selector(requestIDFAWhenActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            return
        }

        ATTrackingManager.requestTrackingAuthorization { status in
            LoggerAnalytics.debug(log: "IDFA Status: \(status.rawValue)")
            if status == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
                LoggerAnalytics.debug(log: "IDFA: \(idfa)")
            }
            completion()
        }
    }
    
    @objc private func requestIDFAWhenActive() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            guard let self else { return }
            LoggerAnalytics.debug(log: "IDFA Status: \(status.rawValue)")
            if status == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
                LoggerAnalytics.debug(log: "IDFA: \(idfa)")
            }
            self.requestNextPermission()
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
            LoggerAnalytics.info(log: "Bluetooth is On")
        case .poweredOff:
            LoggerAnalytics.info(log: "Bluetooth is Off")
        default:
            LoggerAnalytics.debug(log: "Bluetooth state: \(central.state.rawValue)")
        }
        // Trigger completion only after user interaction with Bluetooth alert
        bluetoothCompletion?()
        bluetoothCompletion = nil
    }
}
