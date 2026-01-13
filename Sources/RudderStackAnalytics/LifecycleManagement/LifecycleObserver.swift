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
 */
final class LifecycleObserver {
    @Synchronized private var observers: [WeakObserver] = []
    private var notificationObservers: [NSObjectProtocol] = []
    
    init() {
        registerNotifications()
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
    
    private func handle(_ event: AppLifecycleEvent) {
        let currentObservers = getObserversSnapshot()

        switch event {
        case .background: currentObservers.forEach { $0.onBackground() }
        case .terminate: currentObservers.forEach { $0.onTerminate() }
        case .foreground: currentObservers.forEach { $0.onForeground() }
        case .becomeActive: currentObservers.forEach { $0.onBecomeActive() }
        }
    }

    /// Returns a snapshot of active observers while cleaning up nil references.
    /// This prevents deadlock if any observer tries to add/remove observers during callback.
    private func getObserversSnapshot() -> [LifecycleEventListener] {
        var currentObservers: [LifecycleEventListener] = []
        $observers.modify { observers in
            observers.removeAll { $0.observer == nil }
            currentObservers = observers.compactMap { $0.observer }
        }
        return currentObservers
    }
}

// MARK: - Observer Management
extension LifecycleObserver {
    func addObserver(_ observer: LifecycleEventListener) {
        $observers.modify { observers in
            observers.append(WeakObserver(observer))
        }
    }

    func removeObserver(_ observer: LifecycleEventListener) {
        $observers.modify { observers in
            observers.removeAll { $0.observer === observer }
        }
    }
}
