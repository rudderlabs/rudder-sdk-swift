//
//  LifecycleObserverStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 10/01/26.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - LifecycleObserverStore Tests

@Suite("LifecycleObserverStore Tests")
struct LifecycleObserverStoreTests {
    
    @Test("when adding an observer, then it should be stored and returned in snapshot")
    func testAddObserver() async {
        let store = LifecycleObserverStore()
        let observer = MockLifecycleEventListener()
        
        await store.add(observer)
        let observers = await store.snapshot()
        
        #expect(observers.count == 1)
        #expect(observers.first === observer)
    }
    
    @Test("when adding same observer multiple times, then it should only be stored once")
    func testDuplicateObserverPrevention() async {
        let store = LifecycleObserverStore()
        let observer = MockLifecycleEventListener()
        
        await store.add(observer)
        await store.add(observer)
        await store.add(observer)
        
        let observers = await store.snapshot()
        
        #expect(observers.count == 1)
    }
    
    @Test("when removing an observer by id, then it should no longer be in snapshot")
    func testRemoveObserver() async {
        let store = LifecycleObserverStore()
        let observer1 = MockLifecycleEventListener()
        let observer2 = MockLifecycleEventListener()
        
        await store.add(observer1)
        await store.add(observer2)
        await store.remove(byId: ObjectIdentifier(observer1))
        
        let observers = await store.snapshot()
        
        #expect(observers.count == 1)
        #expect(observers.first === observer2)
    }
    
    @Test("when removing non-existent observer by id, then no error should occur")
    func testRemoveNonExistentObserver() async {
        let store = LifecycleObserverStore()
        let observer1 = MockLifecycleEventListener()
        let observer2 = MockLifecycleEventListener()
        
        await store.add(observer1)
        await store.remove(byId: ObjectIdentifier(observer2))
        
        let observers = await store.snapshot()
        
        #expect(observers.count == 1)
        #expect(observers.first === observer1)
    }
    
    @Test("when observer is deallocated, then snapshot should not include it")
    func testWeakObserverCleanup() async {
        let store = LifecycleObserverStore()
        var weakObserver: MockLifecycleEventListener? = MockLifecycleEventListener()
        let strongObserver = MockLifecycleEventListener()
        
        await store.add(weakObserver!)
        await store.add(strongObserver)
        
        // Deallocate the weak observer
        weakObserver = nil
        
        let observers = await store.snapshot()
        
        #expect(observers.count == 1)
        #expect(observers.first === strongObserver)
    }
    
    @Test("when multiple observers are added, then all should be returned in snapshot")
    func testMultipleObservers() async {
        let store = LifecycleObserverStore()
        let observer1 = MockLifecycleEventListener()
        let observer2 = MockLifecycleEventListener()
        let observer3 = MockLifecycleEventListener()
        
        await store.add(observer1)
        await store.add(observer2)
        await store.add(observer3)
        
        let observers = await store.snapshot()
        
        #expect(observers.count == 3)
    }
    
    @Test("when all observers are removed by id, then snapshot should be empty")
    func testRemoveAllObservers() async {
        let store = LifecycleObserverStore()
        let observer1 = MockLifecycleEventListener()
        let observer2 = MockLifecycleEventListener()
        
        await store.add(observer1)
        await store.add(observer2)
        await store.remove(byId: ObjectIdentifier(observer1))
        await store.remove(byId: ObjectIdentifier(observer2))
        
        let observers = await store.snapshot()
        
        #expect(observers.isEmpty)
    }
}
