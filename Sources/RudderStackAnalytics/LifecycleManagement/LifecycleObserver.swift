//
//  LifecycleObserver.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/03/25.
//

import Foundation

// MARK: - LifecycleObserver
/**
 A class created to observe app lifecycle events.

 It also owns the foreground state of the app. The state starts as background, because the system can
 start a process with no screen. Only a real foreground signal changes it.
 */
final class LifecycleObserver {
    private struct State {
        var observers: [WeakObserver] = []
        var foregroundState: Bool?
    }

    @Synchronized private var state = State()
    private var notificationObservers: [NSObjectProtocol] = []
    // Held across a callback. Take it before the session lock, never after: `SessionHandler` removes its observer while it holds that lock.
    private let deliveryLock = NSRecursiveLock()

    /// Whether the user sees the app now.
    var isInForeground: Bool { foregroundState ?? false }

    /// `nil` until the first read of the app state: an SDK that starts off the main thread reads it a moment later.
    var foregroundState: Bool? { state.foregroundState }
    
    init() {
        registerNotifications()
        readInitialAppState()
    }
    
    deinit {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }
}

// MARK: - Event Management
extension LifecycleObserver {
    private func registerNotifications() {
        AppLifecycleEvent.allCases.forEach { event in
            let observer = NotificationCenter.default.addObserver(
                forName: event.notificationName,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handle(event)
            }
            notificationObservers.append(observer)
        }
    }

    /// An SDK that starts while the app is already on screen receives no foreground notification, so the state is read once.
    private func readInitialAppState() {
        let readAppState: () -> Void = { [weak self] in
            self?.applyInitialAppState(isInForeground: AppState.isInForeground)
        }

        if Thread.isMainThread {
            readAppState()
        } else {
            DispatchQueue.main.async(execute: readAppState)
        }
    }

    /// A lifecycle change that arrived before this read already told the state, and it is the newer fact.
    func applyInitialAppState(isInForeground: Bool) {
        deliveryLock.lock()
        defer { deliveryLock.unlock() }

        guard foregroundState == nil else { return }
        handle(isInForeground ? .foreground : .background)
    }

    func handle(_ event: AppLifecycleEvent) {
        deliveryLock.lock()
        defer { deliveryLock.unlock() }

        switch event {
        // A cold launch posts only `becomeActive`; a return from the background posts both. The first one counts.
        case .foreground, .becomeActive: observersToNotify(ofForeground: true).forEach { $0.onForeground() }
        case .background: observersToNotify(ofForeground: false).forEach { $0.onBackground() }
        case .terminate: activeObservers().forEach { $0.onTerminate() }
        }
    }

    /**
     Records the new foreground state and returns the observers to notify: none when the state did not change.

     One critical section covers both steps. An observer added at the same moment then gets the change
     exactly once: from this snapshot, or from `addObserver`.
     */
    private func observersToNotify(ofForeground isInForeground: Bool) -> [LifecycleEventListener] {
        var observersToNotify: [LifecycleEventListener] = []
        $state.modify { state in
            let wasInForeground = state.foregroundState ?? false
            state.foregroundState = isInForeground
            guard wasInForeground != isInForeground else { return }
            observersToNotify = Self.activeObservers(in: &state)
        }
        return observersToNotify
    }

    private func activeObservers() -> [LifecycleEventListener] {
        var activeObservers: [LifecycleEventListener] = []
        $state.modify { state in
            activeObservers = Self.activeObservers(in: &state)
        }
        return activeObservers
    }

    /// Returns a snapshot of the live observers and drops the released ones.
    /// A snapshot lets an observer add or remove observers during its callback without a deadlock.
    private static func activeObservers(in state: inout State) -> [LifecycleEventListener] {
        state.observers.removeAll { $0.observer == nil }
        return state.observers.compactMap { $0.observer }
    }
}

// MARK: - Observer Management
extension LifecycleObserver {
    /// An observer added while the app is in the foreground receives `onForeground` at once.
    func addObserver(_ observer: LifecycleEventListener) {
        // No lifecycle change can reach the observer between its registration and this catch-up call.
        deliveryLock.lock()
        defer { deliveryLock.unlock() }

        var isInForeground = false
        $state.modify { state in
            state.observers.append(WeakObserver(observer))
            isInForeground = state.foregroundState ?? false
        }

        if isInForeground {
            observer.onForeground()
        }
    }

    func removeObserver(_ observer: LifecycleEventListener) {
        $state.modify { state in
            state.observers.removeAll { $0.observer === observer }
        }
    }
}
