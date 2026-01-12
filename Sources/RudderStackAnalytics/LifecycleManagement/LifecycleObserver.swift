//
//  LifeCycleObserver.swift
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
        $observers.modify { observers in
            observers.removeAll { $0.observer == nil }
            switch event {
            case .background: observers.forEach { $0.observer?.onBackground() }
            case .terminate: observers.forEach { $0.observer?.onTerminate() }
            case .foreground: observers.forEach { $0.observer?.onForeground() }
            case .becomeActive: observers.forEach { $0.observer?.onBecomeActive() }
            }
        }
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
