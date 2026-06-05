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
import UserNotifications

/// The permission types this manager can request.
enum PermissionType {
    case idfa
    case bluetooth
    case pushNotification
}

/**
 Requests a sequence of iOS permissions and guarantees the completion is invoked.

 ## Guarantees
 - **Order independent.** Any ordering of `[.idfa, .bluetooth, .pushNotification]` works.
 - **Simulator-safe.** Hardware that doesn't support a permission (BLE on simulator,
 push without entitlement, etc.) can't stall the chain — every wait has a timeout.
 - **Lifetime-safe.** The internal `Task` strongly retains `self` for the duration of
 the chain, so a local-scoped caller can't free the manager mid-flight.

 ## Usage
 ```swift
    private let permissionManager = PermissionManager()

    permissionManager.requestPermissions([.idfa, .pushNotification, .bluetooth]) {
    // Always called — even on simulator, even if the user denies permissions.
        AnalyticsManager.shared.initializeAnalyticsSDK()
    }

    // In AppDelegate, forward BOTH success and failure to unblock the push step:
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken _: Data) {
        permissionManager.didRegisterForRemoteNotifications()
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        permissionManager.didRegisterForRemoteNotifications()
    }
 ```
 */
@MainActor
final class PermissionManager: NSObject {

    // MARK: - Tunables

    /// Time `centralManagerDidUpdateState` has to fire before we abandon the wait.
    /// Required because the simulator (no BLE hardware) sometimes never delivers
    /// a state transition.
    private static let bluetoothTimeoutNanos: UInt64 = 1 * NSEC_PER_SEC

    /// Time the AppDelegate has to forward `didRegisterForRemoteNotifications()`
    /// after `registerForRemoteNotifications()`. Protects against simulators
    /// and apps without the push entitlement, where neither success nor failure
    /// delegate methods ever fire.
    private static let pushTokenTimeoutNanos: UInt64 = 5 * NSEC_PER_SEC

    /// Time `UIApplication.didBecomeActiveNotification` has to fire before we
    /// abandon the wait. Guards against background launches and other edge
    /// cases where the notification never arrives.
    private static let didBecomeActiveTimeoutNanos: UInt64 = 5 * NSEC_PER_SEC

    // MARK: - State

    private var centralManager: CBCentralManager?
    private var bluetoothContinuation: CheckedContinuation<Void, Never>?
    private var pushTokenContinuation: CheckedContinuation<Void, Never>?
    private var didBecomeActiveContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Public API

    /// Request a sequence of permissions. `completion` is guaranteed to run on
    /// the main thread after the last permission resolves (or times out).
    func requestPermissions(_ permissions: [PermissionType], completion: @escaping () -> Void) {
        // The Task strongly captures `self`, so callers can store the manager
        // wherever they like — it stays alive until the chain finishes.
        Task {
            for permission in permissions {
                await self.request(permission)
            }
            completion()
        }
    }

    /// async/await variant for callers that don't need a closure.
    func requestPermissions(_ permissions: [PermissionType]) async {
        for permission in permissions {
            await request(permission)
        }
    }

    /// Forward from BOTH
    /// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` AND
    /// `application(_:didFailToRegisterForRemoteNotificationsWithError:)`.
    func didRegisterForRemoteNotifications() {
        resumePushToken()
    }

    private func request(_ permission: PermissionType) async {
        switch permission {
        case .idfa:             await requestIDFA()
        case .pushNotification: await requestPushNotification()
        case .bluetooth:        await requestBluetooth()
        }
    }
}

// MARK: - IDFA
extension PermissionManager {
    fileprivate func requestIDFA() async {
        // ATT only presents the prompt while the app is foreground/active. If
        // we're called from `didFinishLaunchingWithOptions`, wait for the
        // didBecomeActive transition first.
        if UIApplication.shared.applicationState != .active {
            await waitForActive()
        }
        let status = await ATTrackingManager.requestTrackingAuthorization()
        print("IDFA status: \(status.rawValue)")
        if status == .authorized {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
            print("IDFA: \(idfa)")
        }
    }

    /// Uses the selector-based observer API so we don't have to capture an
    /// `NSObjectProtocol` token inside a `@Sendable` notification closure.
    /// `removeObserver(self, name:)` correspondingly tears it down.
    private func waitForActive() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            didBecomeActiveContinuation = cont
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            // Safety net for background launches / edge cases where
            // didBecomeActiveNotification never arrives.
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: Self.didBecomeActiveTimeoutNanos)
                if self?.didBecomeActiveContinuation != nil {
                    print("didBecomeActive not received within timeout; continuing chain.")
                }
                self?.resumeDidBecomeActive()
            }
        }
    }

    @objc private func handleDidBecomeActive() {
        resumeDidBecomeActive()
    }

    private func resumeDidBecomeActive() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        let cont = didBecomeActiveContinuation
        didBecomeActiveContinuation = nil
        cont?.resume()
    }
}

// MARK: - Push Notification
extension PermissionManager {
    fileprivate func requestPushNotification() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        print("Push authorization granted: \(granted)")
        guard granted else { return }

        UIApplication.shared.registerForRemoteNotifications()
        await waitForPushToken()
    }

    private func waitForPushToken() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            pushTokenContinuation = cont
            // Safety net for simulator / missing push entitlement.
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: Self.pushTokenTimeoutNanos)
                if self?.pushTokenContinuation != nil {
                    print("Push token registration timed out; continuing chain.")
                }
                self?.resumePushToken()
            }
        }
    }

    fileprivate func resumePushToken() {
        let cont = pushTokenContinuation
        pushTokenContinuation = nil
        cont?.resume()
    }
}

// MARK: - Bluetooth
extension PermissionManager: CBCentralManagerDelegate {

    fileprivate func requestBluetooth() async {
        // If iOS already knows the answer, no permission alert will appear and
        // (on some platforms) the state callback won't fire either. Short-circuit.
        if CBCentralManager.authorization != .notDetermined {
            print("Bluetooth authorization: \(CBCentralManager.authorization.rawValue)")
            return
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            bluetoothContinuation = cont
            centralManager = CBCentralManager(delegate: self, queue: .main)
            // Safety net for simulator / .unsupported hardware that never
            // delivers a state transition.
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: Self.bluetoothTimeoutNanos)
                if self?.bluetoothContinuation != nil {
                    print("Bluetooth state did not resolve within timeout; continuing chain.")
                }
                self?.resumeBluetooth()
            }
        }
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // CBCentralManager was initialized with `queue: .main`, so this is
        // already on the main thread — but the protocol method isn't isolated,
        // so hop explicitly to satisfy the type system.
        let state = central.state
        Task { @MainActor in
            switch state {
            case .poweredOn:    print("Bluetooth is On")
            case .poweredOff:   print("Bluetooth is Off")
            case .unsupported:  print("Bluetooth not supported (e.g. simulator)")
            case .unauthorized: print("Bluetooth permission denied")
            default:            print("Bluetooth state: \(state.rawValue)")
            }
            // `.unknown` is the pre-init state; only resume on a real transition.
            guard state != .unknown else { return }
            self.resumeBluetooth()
        }
    }

    private func resumeBluetooth() {
        let cont = bluetoothContinuation
        bluetoothContinuation = nil
        cont?.resume()
    }
}
