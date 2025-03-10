//
//  LifecycleManagementPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 10/03/25.
//

import Foundation

final class LifecycleManagementPlugin: Plugin {
    var pluginType: PluginType = .manual
    var analytics: AnalyticsClient?
    
    private var observers: [WeakObserver] = []
    private var notificationObservers: [NSObjectProtocol] = []
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.registerNotifications()
    }
    
    deinit {
        self.notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}

extension LifecycleManagementPlugin {
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
        }
    }
    
    private func notifyObservers(_ action: (LifecycleEventObserver) -> Void) {
        observers.removeAll { $0.observer == nil } // Clean up nil references
        
        for wrapper in observers {
            if let observer = wrapper.observer {
                action(observer)
            }
        }
    }
}

// MARK: - Observer Management
extension LifecycleManagementPlugin {
    func addObserver(_ observer: LifecycleEventObserver) {
        observers.append(WeakObserver(observer))
    }
    
    func removeObserver(_ observer: LifecycleEventObserver) {
        observers.removeAll { $0.observer === observer }
    }
}
