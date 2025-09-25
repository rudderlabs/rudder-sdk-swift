//
//  PermissionManager.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 16/02/25.
//

import Foundation
import CoreBluetooth
import AppTrackingTransparency
import AdSupport
import RudderStackAnalytics
import UIKit

/**
 Defines the different types of permissions that can be requested through the PermissionManager.
 */
enum PermissionType {
    case idfa
    case bluetooth
    case pushNotification
}

/**
  A centralized manager for requesting and handling various iOS permissions in sequence.
  This class provides a clean interface for requesting multiple permissions one after another,
  ensuring a smooth user experience without overwhelming users with multiple permission dialogs at once.
 
  ## What it does:
  - Requests advertising identifier (IDFA) permission
  - Requests Bluetooth permission
  - Requests push notification permission
  - Handles permissions sequentially to avoid dialog overload
 
  ## Usage:
  ```swift
  let permissionManager = PermissionManager()
  
  // Request multiple permissions in sequence
  permissionManager.requestPermissions([.idfa, .bluetooth, .pushNotification]) {
      print("All permissions have been processed")
      // Continue with app initialization
  }
  
  // For push notifications, call this from AppDelegate when device token is received
  permissionManager.didRegisterForRemoteNotifications()
  ```
 
  ## How it works:
  1. **Sequential Processing** - Permissions are requested one at a time from a queue
  2. **User-Friendly** - Prevents multiple permission dialogs from appearing simultaneously
  3. **Completion Tracking** - Calls completion handler when all permissions are processed
  4. **State Management** - Handles various permission states (granted, denied, not determined)
 
  - Note: This class must be used from the main thread due to UI permission dialogs
  - Important: For push notifications, make sure to call `didRegisterForRemoteNotifications()` from AppDelegate
 */

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
            LoggerAnalytics.debug("IDFA Status: \(status.rawValue)")
            if status == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
                LoggerAnalytics.debug("IDFA: \(idfa)")
            }
            completion()
        }
    }
    
    @objc private func requestIDFAWhenActive() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            guard let self else { return }
            LoggerAnalytics.debug("IDFA Status: \(status.rawValue)")
            if status == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
                LoggerAnalytics.debug("IDFA: \(idfa)")
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
            LoggerAnalytics.debug("Bluetooth state: \(central.state.rawValue)")
        }
        // Trigger completion only after user interaction with Bluetooth alert
        bluetoothCompletion?()
        bluetoothCompletion = nil
    }
}
