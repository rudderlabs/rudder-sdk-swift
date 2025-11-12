//
//  StateManagementTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 07/01/25.
//

import Testing
import Combine
@testable import RudderStackAnalytics

@Suite("State Management Framework Tests")
struct StateManagementTests {
    
    @Test("given initial state value, when creating state, then type and value are preserved")
    func testCreateStateWithInitialValue() {
        let value: Int = 42
        
        let stateInstance = createState(initialState: value)
        
        #expect(type(of: value) == type(of: stateInstance.state.value))
        #expect(stateInstance.state.value == value)
    }
    
    @Test("given string values, when creating states, then values are preserved", 
          arguments: ["Hello", "World", "", "Test String", "🚀"])
    func testCreateStateWithStringTypes(value: String) {
        let stringState = createState(initialState: value)
        
        #expect(stringState.state.value == value)
    }
    
    @Test("given integer values, when creating states, then values are preserved",
          arguments: [0, 1, -1, 42, 100, Int.max, Int.min])
    func testCreateStateWithIntegerTypes(value: Int) {
        let intState = createState(initialState: value)
        
        #expect(intState.state.value == value)
    }
    
    @Test("given boolean values, when creating states, then values are preserved",
          arguments: [true, false])
    func testCreateStateWithBooleanTypes(value: Bool) {
        let boolState = createState(initialState: value)
        
        #expect(boolState.state.value == value)
    }
    
    @Test("given optional values, when creating states, then values are preserved")
    func testCreateStateWithOptionalTypes() {
        let nilOptionalState = createState(initialState: Optional<String>.none)
        #expect(nilOptionalState.state.value == nil)
        
        let someOptionalState = createState(initialState: Optional<String>.some("test"))
        #expect(someOptionalState.state.value == "test")
    }
    
    @Test("given array values, when creating states, then values are preserved",
          arguments: [[], [1], [1, 2, 3], [1, 2, 3, 4, 5]])
    func testCreateStateWithArrayTypes(value: [Int]) {
        let arrayState = createState(initialState: value)
        
        #expect(arrayState.state.value == value)
    }
    
    @Test("given custom struct values, when creating states, then values are preserved")
    func testCreateStateWithCustomStructTypes() {
        struct TestStruct: Equatable { 
            let id: Int 
            let name: String
        }
        
        let testValues = [
            TestStruct(id: 1, name: "First"),
            TestStruct(id: 2, name: "Second"),
            TestStruct(id: 100, name: "Test")
        ]
        
        for testValue in testValues {
            let structState = createState(initialState: testValue)
            
            #expect(structState.state.value == testValue)
        }
    }
    
    @Test("given initial state, when dispatching single action, then state updates correctly")
    func testMockActionUpdatesState() {
        let stateInstance = createState(initialState: 0)
        
        let mockAction = MockStateAction<Int> { currentState in
            currentState + 5
        }
        stateInstance.dispatch(action: mockAction)
        
        #expect(stateInstance.state.value == 5)
    }
    
    @Test("given initial state, when dispatching multiple sequential actions, then state updates correctly")
    func testMultipleMockActionsUpdatesState() {
        let stateInstance = createState(initialState: 0)
        
        let mockAction1 = MockStateAction<Int> { currentState in
            currentState + 5
        }
        
        let mockAction2 = MockStateAction<Int> { currentState in
            currentState + 15
        }
        
        let mockAction3 = MockStateAction<Int> { currentState in
            currentState - 8
        }
        
        stateInstance.dispatch(action: mockAction1)  // 0 + 5 = 5
        stateInstance.dispatch(action: mockAction2)  // 5 + 15 = 20
        stateInstance.dispatch(action: mockAction3)  // 20 - 8 = 12
        
        #expect(stateInstance.state.value == 12)
    }
    
    @Test("given subscribed state, when dispatching actions, then subscription receives all updates")
    func testMockActionSubscriptionUpdatesState() {
        let stateInstance = createState(initialState: 0)
        var cancellables = Set<AnyCancellable>()
        var updatedValue = 0
        
        stateInstance.state.sink { newValue in
            updatedValue = newValue
        }.store(in: &cancellables)
        
        let mockAction1 = MockStateAction<Int> { currentState in
            currentState + 15
        }
        
        let mockAction2 = MockStateAction<Int> { currentState in
            currentState - 5
        }
        
        stateInstance.dispatch(action: mockAction1)  // 0 + 15 = 15
        stateInstance.dispatch(action: mockAction2)  // 15 - 5 = 10
        
        #expect(updatedValue == 10)
    }
    
    @Test("given reference type state, when dispatching mutation action, then original data remains immutable")
    func testStateImmutabilityThroughActions() {
        let initialArray = [1, 2, 3]
        let stateInstance = createState(initialState: initialArray)
        
        let modifyAction = MockStateAction<[Int]> { currentArray in
            var newArray = currentArray
            newArray.append(4)
            return newArray
        }
        
        stateInstance.dispatch(action: modifyAction)
        
        #expect(initialArray == [1, 2, 3]) // Original unchanged
        #expect(stateInstance.state.value == [1, 2, 3, 4]) // State updated
    }
    
    @Test("given multiple subscribers, when dispatching actions, then all subscribers receive same updates")
    func testMultipleSubscribersReceiveSameUpdates() {
        let stateInstance = createState(initialState: 0)
        var subscriber1Values: [Int] = []
        var subscriber2Values: [Int] = []
        var cancellables = Set<AnyCancellable>()
        
        stateInstance.state.sink { value in
            subscriber1Values.append(value)
        }.store(in: &cancellables)
        
        stateInstance.state.sink { value in
            subscriber2Values.append(value)
        }.store(in: &cancellables)
        
        // When: Dispatch actions
        let actions = [
            MockStateAction<Int> { $0 + 5 },   // 0 + 5 = 5
            MockStateAction<Int> { $0 * 2 },   // 5 * 2 = 10
            MockStateAction<Int> { $0 - 3 }    // 10 - 3 = 7
        ]
        
        actions.forEach { stateInstance.dispatch(action: $0) }
        
        #expect(subscriber1Values == subscriber2Values)
        #expect(subscriber1Values == [0, 5, 10, 7])
    }
    
    @Test("given complex state structure, when applying transformation action, then all properties update correctly")
    func testActionWithComplexStateTransformation() {
        struct AppState: Equatable {
            var counter: Int
            var isEnabled: Bool
            var items: [String]
        }
        
        let initialState = AppState(counter: 0, isEnabled: false, items: [])
        let stateInstance = createState(initialState: initialState)
        
        let complexAction = MockStateAction<AppState> { currentState in
            AppState(
                counter: currentState.counter + 1,
                isEnabled: !currentState.isEnabled,
                items: currentState.items + ["new_item"]
            )
        }
        
        stateInstance.dispatch(action: complexAction)
        
        let finalState = stateInstance.state.value
        #expect(finalState.counter == 1)
        #expect(finalState.isEnabled)
        #expect(finalState.items == ["new_item"])
    }
    
    @Test("given state with invariants, when applying action chain, then invariants are maintained")
    func testStatePersistenceThroughActionChain() {
        struct CounterState: Equatable {
            let count: Int
            
            // Invariant: count should never be negative
            init(count: Int) {
                self.count = max(0, count)
            }
        }
        
        let stateInstance = createState(initialState: CounterState(count: 5))
        
        let actions = [
            MockStateAction<CounterState> { _ in CounterState(count: 10) },        // 10
            MockStateAction<CounterState> { state in CounterState(count: state.count - 15) }, // max(0, -5) = 0
            MockStateAction<CounterState> { state in CounterState(count: state.count + 3) }   // 0 + 3 = 3
        ]
        
        actions.forEach { stateInstance.dispatch(action: $0) }
        
        #expect(stateInstance.state.value.count == 3)
    }
    
    @Test("given different state types, when applying matching actions, then type safety is enforced")
    func testStateTypeSafetyWithMatchingActionTypes() {
        let intState = createState(initialState: 0)
        let stringState = createState(initialState: "hello")
        
        let intAction = MockStateAction<Int> { $0 + 1 }
        let stringAction = MockStateAction<String> { $0 + " world" }
        
        intState.dispatch(action: intAction)
        stringState.dispatch(action: stringAction)
        
        #expect(intState.state.value == 1)
        #expect(stringState.state.value == "hello world")
    }
    
    @Test("given same initial values, when creating multiple states, then instances are independent")
    func testStateFactoryFunctionCreatesIndependentInstances() {
        let state1 = createState(initialState: 10)
        let state2 = createState(initialState: 10)
        
        let action1 = MockStateAction<Int> { $0 + 5 }
        let action2 = MockStateAction<Int> { $0 * 2 }
        
        state1.dispatch(action: action1)
        state2.dispatch(action: action2)
        
        #expect(state1.state.value == 15)
        #expect(state2.state.value == 20)
        #expect(state1.state.value != state2.state.value)
    }
    
    @Test("given active subscriptions, when cleaning up, then memory is managed properly")
    func testStateSubscriptionCleanupAndMemoryManagement() {
        let stateInstance = createState(initialState: 0)
        var receivedValues: [Int] = []
        var cancellables: Set<AnyCancellable>? = Set<AnyCancellable>()
        
        defer {
            cancellables?.removeAll()
            cancellables = nil
        }
        
        stateInstance.state.sink { value in
            receivedValues.append(value)
        }.store(in: &cancellables!)
        
        let action = MockStateAction<Int> { $0 + 1 }
        stateInstance.dispatch(action: action)
        
        #expect(receivedValues == [0, 1])
        
        stateInstance.dispatch(action: action)
        #expect(receivedValues == [0, 1]) // Should not have changed
        #expect(stateInstance.state.value == 2) // But state should still be updated
    }
}
