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
    private let observerStore = LifecycleObserverStore()
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
        // Capture store explicitly to avoid implicit self capture.
        Task { @MainActor [observerStore] in
            let observers = await observerStore.snapshot()

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
        // Capture observer weakly to avoid extending its lifetime if Task is delayed.
        // Also capture store explicitly to avoid implicit self capture.
        Task { [weak observer, observerStore] in
            guard let observer = observer else { return }
            await observerStore.add(observer)
        }
    }

    func removeObserver(_ observer: LifecycleEventListener) {
        // Capture ObjectIdentifier instead of observer to avoid strong reference.
        // This is safe to call from deinit as it won't extend the observer's lifetime.
        let observerId = ObjectIdentifier(observer)
        Task { [observerStore] in
            await observerStore.remove(byId: observerId)
        }
    }
}

// MARK: - LifecycleObserverStore
/**
 An actor to manage lifecycle event observers safely across concurrent contexts.
 */
actor LifecycleObserverStore {
    
    private var observers: [WeakObserver] = []
    
    func add(_ observer: LifecycleEventListener) {
        guard observers.contains(where: { $0.id == ObjectIdentifier(observer) }) == false else { return }
        observers.append(WeakObserver(observer))
    }
    
    func remove(byId id: ObjectIdentifier) {
        observers.removeAll { $0.id == id }
    }
    
    // Snapshot of current observers, cleaning up any that have been deallocated.
    func snapshot() -> [LifecycleEventListener] {
        observers.removeAll { $0.observer == nil }
        return observers.compactMap { $0.observer }
    }
}
