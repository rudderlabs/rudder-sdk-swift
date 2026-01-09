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
    private let store = LifecycleObserverStore()
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
        Task {
            let observers = await store.snapshot()
            
            switch event {
            case .background: observers.forEach { $0.onBackground() }
            case .terminate: observers.forEach { $0.onTerminate() }
            case .foreground: observers.forEach { $0.onForeground() }
            case .becomeActive: observers.forEach { $0.onBecomeActive() }
            }
        }
    }
}

// MARK: - Observer Management
extension LifecycleObserver {
    func addObserver(_ observer: LifecycleEventListener) {
        Task { await store.add(observer) }
    }
    
    func removeObserver(_ observer: LifecycleEventListener) {
        Task { await store.remove(observer) }
    }
}

// MARK: - LifecycleObserverStore
/**
 An actor to manage lifecycle event observers safely across concurrent contexts.
 */
actor LifecycleObserverStore {
    
    private var observers: [WeakObserver] = []
    
    func add(_ observer: LifecycleEventListener) {
        guard observers.contains(where: { $0.observer === observer }) == false else { return }
        observers.append(WeakObserver(observer))
    }
    
    func remove(_ observer: LifecycleEventListener) {
        observers.removeAll { $0.observer === observer }
    }
    
    func snapshot() -> [LifecycleEventListener] {
        observers.removeAll { $0.observer == nil }
        return observers.compactMap { $0.observer }
    }
}
