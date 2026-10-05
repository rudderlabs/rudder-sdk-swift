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
        var isInForeground = false
    }

    @Synchronized private var state = State()
    private var notificationObservers: [NSObjectProtocol] = []

    /// Whether the user sees the app now.
    var isInForeground: Bool { state.isInForeground }
    
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

    /// An SDK that starts while the app is already active receives no foreground notification, so the state is read once.
    private func readInitialAppState() {
        let readAppState = { [weak self] in
            guard AppState.isActive else { return }
            self?.handle(.becomeActive)
        }

        if Thread.isMainThread {
            readAppState()
        } else {
            DispatchQueue.main.async(execute: readAppState)
        }
    }

    func handle(_ event: AppLifecycleEvent) {
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
            guard state.isInForeground != isInForeground else { return }
            state.isInForeground = isInForeground
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
        var isInForeground = false
        $state.modify { state in
            state.observers.append(WeakObserver(observer))
            isInForeground = state.isInForeground
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
