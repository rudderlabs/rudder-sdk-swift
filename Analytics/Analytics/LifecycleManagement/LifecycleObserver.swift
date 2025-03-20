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
    var analytics: AnalyticsClient?
    
    private var observers: [WeakObserver] = []
    private var notificationObservers: [NSObjectProtocol] = []
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.registerNotifications()
    }
    
    deinit {
        self.observers.removeAll()
        self.notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}

// MARK: - Event Management
extension LifecycleObserver {
    func registerNotifications() {
        AppLifecycleEvent.allCases.forEach { event in
            let observer = NotificationCenter.default.addObserver(forName: event.notificationName, object: nil, queue: .main) { _ in
                self.handleEvent(event)
            }
            notificationObservers.append(observer)
        }
    }
    
    private func handleEvent(_ event: AppLifecycleEvent) {
        switch event {
        case .background: notifyObservers { $0.onBackground() }
        case .terminate: notifyObservers { $0.onTerminate() }
        case .foreground: notifyObservers { $0.onForeground() }
        case .becomeActive: notifyObservers { $0.onBecomeActive() }
        }
    }
    
    private func notifyObservers(_ action: (LifecycleEventListener) -> Void) {
        observers.removeAll { $0.observer == nil } // Clean up nil references
        
        for wrapper in observers {
            if let observer = wrapper.observer {
                action(observer)
            }
        }
    }
}

// MARK: - Observer Management
extension LifecycleObserver {
    func addObserver(_ observer: LifecycleEventListener) {
        observers.append(WeakObserver(observer))
    }
    
    func removeObserver(_ observer: LifecycleEventListener) {
        observers.removeAll { $0.observer === observer }
    }
}
