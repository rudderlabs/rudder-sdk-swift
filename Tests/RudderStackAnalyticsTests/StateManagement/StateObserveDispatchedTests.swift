//
//  StateObserveDispatchedTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 17/07/26.
//

import Testing
import Combine
import Foundation
@testable import RudderStackAnalytics

@Suite("State observeDispatched Tests")
struct StateObserveDispatchedTests {

    private struct IncrementAction: StateAction {
        typealias T = Int
        let newValue: Int
        func reduce(currentState: Int) -> Int { return newValue }
    }

    // MARK: - Seed skipping

    @Test("Given a state with no dispatch, When observeDispatched is subscribed, Then the initial value is not emitted")
    func testInitialValueIsSkipped() {
        let state = createState(initialState: 0)
        var received: [Int] = []
        let cancellable = state.observeDispatched().sink { received.append($0) }
        defer { cancellable.cancel() }

        #expect(received.isEmpty)
    }

    @Test("Given an early subscriber, When a value is dispatched, Then only the dispatched value is emitted")
    func testEarlySubscriberSkipsSeedAndReceivesDispatched() {
        let state = createState(initialState: 0)
        var received: [Int] = []
        let cancellable = state.observeDispatched().sink { received.append($0) }
        defer { cancellable.cancel() }

        state.dispatch(action: IncrementAction(newValue: 1))
        state.dispatch(action: IncrementAction(newValue: 2))

        #expect(received == [1, 2])
    }

    // MARK: - Late subscriber (the regression this guards)

    @Test("Given a value dispatched before subscription, When observeDispatched is subscribed late, Then the current value is emitted immediately")
    func testLateSubscriberReceivesCurrentDispatchedValue() {
        let state = createState(initialState: 0)
        state.dispatch(action: IncrementAction(newValue: 1))

        var received: [Int] = []
        let cancellable = state.observeDispatched().sink { received.append($0) }
        defer { cancellable.cancel() }

        #expect(received == [1], "a late subscriber must receive the already dispatched value, not lose it")
    }

    @Test("Given a late subscriber, When further values are dispatched, Then all of them are emitted")
    func testLateSubscriberReceivesSubsequentValues() {
        let state = createState(initialState: 0)
        state.dispatch(action: IncrementAction(newValue: 1))

        var received: [Int] = []
        let cancellable = state.observeDispatched().sink { received.append($0) }
        defer { cancellable.cancel() }

        state.dispatch(action: IncrementAction(newValue: 2))

        #expect(received == [1, 2])
    }

    // MARK: - publisher vs observeDispatched

    @Test("Given a state, When publisher is subscribed, Then the initial value is emitted")
    func testPublisherEmitsInitialValue() {
        let state = createState(initialState: 7)
        var received: [Int] = []
        let cancellable = state.publisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        #expect(received == [7], "publisher must still replay the current value, including the seed")
    }

    // MARK: - Seed is never observed, even while dispatches are in flight

    @Test("Given subscribers attaching while dispatches are in flight, When they observe, Then the initial value is never emitted")
    func testInitialValueNeverLeaksToConcurrentSubscribers() {
        let seed = -1
        let state = createState(initialState: seed)
        let leaked = Synchronized(wrappedValue: false)

        // Subscribers attach concurrently with dispatches, so some land mid-dispatch. None of them
        // may ever observe the seed, whatever the interleaving.
        DispatchQueue.concurrentPerform(iterations: 200) { index in
            if index.isMultiple(of: 2) {
                state.dispatch(action: IncrementAction(newValue: index))
            } else {
                let cancellable = state.observeDispatched().sink { value in
                    if value == seed { leaked.wrappedValue = true }
                }
                cancellable.cancel()
            }
        }

        #expect(leaked.wrappedValue == false, "observeDispatched must never emit the initial value")
    }

    // MARK: - Atomicity

    @Test("Given concurrent dispatches, When they all complete, Then no update is lost")
    func testConcurrentDispatchesDoNotLoseUpdates() {
        let state = createState(initialState: 0)
        let iterations = 500

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            state.dispatch(action: CountingAction())
        }

        #expect(state.value == iterations, "read-reduce-write must be atomic; got \(state.value) of \(iterations)")
    }

    private struct CountingAction: StateAction {
        typealias T = Int
        func reduce(currentState: Int) -> Int { return currentState + 1 }
    }
}
