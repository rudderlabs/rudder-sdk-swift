//
//  UpdateSourceConfigActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 12/11/25.
//

import Testing
import Combine
@testable import RudderStackAnalytics

@Suite("UpdateSourceConfigAction Tests")
struct UpdateSourceConfigActionTests {
    
    // MARK: - Basic Functionality Tests
    
    @Test("given current source config, when updating with new config, then state is completely replaced")
    func testUpdateSourceConfigActionReplacesCurrentState() {
        let currentConfig = createCustomSourceConfig(
            sourceId: "current-id",
            sourceName: "Current Source",
            isEnabled: false
        )
        
        let newConfig = createCustomSourceConfig(
            sourceId: "new-id",
            sourceName: "New Source",
            isEnabled: true
        )
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        let result = action.reduce(currentState: currentConfig)
        
        #expect(result.source.sourceId == "new-id")
        #expect(result.source.sourceName == "New Source")
        #expect(result.source.isSourceEnabled == true)
    }
    
    @Test("given source config with destinations, when updating, then destinations are preserved")
    func testUpdateSourceConfigActionPreservesDestinations() {
        let destination1 = createCustomDestination(id: "dest-1", name: "Destination 1")
        let destination2 = createCustomDestination(id: "dest-2", name: "Destination 2")
        
        let currentConfig = createCustomSourceConfig(destinations: [destination1])
        let newConfig = createCustomSourceConfig(destinations: [destination1, destination2])
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        let result = action.reduce(currentState: currentConfig)
        
        #expect(result.source.destinations.count == 2)
        #expect(result.source.destinations[0].destinationId == "dest-1")
        #expect(result.source.destinations[1].destinationId == "dest-2")
    }
        
    @Test("given state instance, when dispatching update action, then state updates correctly")
    func testUpdateSourceConfigActionWithStateManagement() {
        let initialConfig = createCustomSourceConfig(sourceId: "initial", isEnabled: false)
        let stateInstance = createState(initialState: initialConfig)
        
        let newConfig = createCustomSourceConfig(sourceId: "updated", isEnabled: true)
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        stateInstance.dispatch(action: action)
        
        let currentState = stateInstance.state.value
        #expect(currentState.source.sourceId == "updated")
        #expect(currentState.source.isSourceEnabled == true)
    }
    
    @Test("given subscribed state, when updating config, then subscribers receive updates")
    func testUpdateSourceConfigActionNotifiesSubscribers() {
        let initialConfig = createCustomSourceConfig(sourceId: "initial")
        let stateInstance = createState(initialState: initialConfig)
        
        var receivedConfigs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        stateInstance.state.sink { config in
            receivedConfigs.append(config)
        }.store(in: &cancellables)
        
        let config1 = createCustomSourceConfig(sourceId: "update-1")
        let config2 = createCustomSourceConfig(sourceId: "update-2")
        
        let action1 = UpdateSourceConfigAction(updatedSourceConfig: config1)
        let action2 = UpdateSourceConfigAction(updatedSourceConfig: config2)
        
        stateInstance.dispatch(action: action1)
        stateInstance.dispatch(action: action2)
        
        #expect(receivedConfigs.count == 3) // Initial + 2 updates
        #expect(receivedConfigs[0].source.sourceId == "initial")
        #expect(receivedConfigs[1].source.sourceId == "update-1")
        #expect(receivedConfigs[2].source.sourceId == "update-2")
    }
    
    // MARK: - Property Preservation Tests
    
    @Test("given config with all properties, when updating, then all properties are preserved",
          arguments: [
            ("source-1", "Source One", "key-1", true, "workspace-1", "2025-01-01"),
            ("source-2", "Source Two", "key-2", false, "workspace-2", "2025-01-02"),
            ("", "", "", true, "", ""),
            ("special-🚀-id", "Special Source 🎯", "super-key-123", false, "workspace-special", "2025-12-31")
          ])
    func testUpdateSourceConfigActionPreservesAllProperties(
        sourceId: String,
        sourceName: String,
        writeKey: String,
        isEnabled: Bool,
        workspaceId: String,
        updatedAt: String
    ) {
        let currentConfig = createCustomSourceConfig()
        let newConfig = createCustomSourceConfig(
            sourceId: sourceId,
            sourceName: sourceName,
            writeKey: writeKey,
            isEnabled: isEnabled,
            workspaceId: workspaceId,
            updatedAt: updatedAt
        )
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        let result = action.reduce(currentState: currentConfig)
        
        #expect(result.source.sourceId == sourceId)
        #expect(result.source.sourceName == sourceName)
        #expect(result.source.writeKey == writeKey)
        #expect(result.source.isSourceEnabled == isEnabled)
        #expect(result.source.workspaceId == workspaceId)
        #expect(result.source.updatedAt == updatedAt)
    }
    
    // MARK: - Immutability Tests
    
    @Test("given original configs, when applying action, then original configs remain unchanged")
    func testUpdateSourceConfigActionMaintainsImmutability() {
        let originalCurrent = createCustomSourceConfig(sourceId: "original-current")
        let originalNew = createCustomSourceConfig(sourceId: "original-new")
        
        let currentSourceId = originalCurrent.source.sourceId
        let newSourceId = originalNew.source.sourceId
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: originalNew)
        _ = action.reduce(currentState: originalCurrent)
        
        #expect(originalCurrent.source.sourceId == currentSourceId)
        #expect(originalNew.source.sourceId == newSourceId)
    }
    
    // MARK: - Edge Cases
    
    @Test("given config with empty destinations, when updating with destinations, then destinations are added")
    func testUpdateSourceConfigActionHandlesEmptyDestinations() {
        let currentConfig = createCustomSourceConfig(destinations: [])
        let destination = createCustomDestination()
        let newConfig = createCustomSourceConfig(destinations: [destination])
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        let result = action.reduce(currentState: currentConfig)
        
        #expect(result.source.destinations.count == 1)
        #expect(result.source.destinations[0].destinationId == "dest-1")
    }
    
    @Test("given config with destinations, when updating with empty destinations, then destinations are removed")
    func testUpdateSourceConfigActionHandlesDestinationRemoval() {
        let destination = createCustomDestination()
        let currentConfig = createCustomSourceConfig(destinations: [destination])
        let newConfig = createCustomSourceConfig(destinations: [])
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        let result = action.reduce(currentState: currentConfig)
        
        #expect(result.source.destinations.isEmpty)
    }
    
    @Test("given initial state config, when updating, then initial state is replaced")
    func testUpdateSourceConfigActionReplacesInitialState() {
        let initialConfig = SourceConfig.initialState()
        let realConfig = createCustomSourceConfig(
            sourceId: "real-source",
            sourceName: "Real Source",
            writeKey: "real-key"
        )
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: realConfig)
        let result = action.reduce(currentState: initialConfig)
        
        #expect(result.source.sourceId == "real-source")
        #expect(result.source.sourceName == "Real Source")
        #expect(result.source.writeKey == "real-key")
        #expect(result.source.sourceId != String.empty)
    }
}

// MARK: - Test Data Helpers using SwiftTestMockProvider

extension UpdateSourceConfigActionTests {
    private func createCustomSourceConfig(
        sourceId: String? = nil,
        sourceName: String? = nil,
        writeKey: String? = nil,
        isEnabled: Bool? = nil,
        workspaceId: String? = nil,
        updatedAt: String? = nil,
        destinations: [Destination]? = nil
    ) -> SourceConfig {
        let baseMock = SwiftTestMockProvider.mockSourceConfig
        
        let customSource = RudderServerConfigSource(
            sourceId: sourceId ?? baseMock.source.sourceId,
            sourceName: sourceName ?? baseMock.source.sourceName,
            writeKey: writeKey ?? baseMock.source.writeKey,
            isSourceEnabled: isEnabled ?? baseMock.source.isSourceEnabled,
            workspaceId: workspaceId ?? baseMock.source.workspaceId,
            updatedAt: updatedAt ?? baseMock.source.updatedAt,
            metricConfig: baseMock.source.metricConfig,
            destinations: destinations ?? baseMock.source.destinations
        )
        
        return SourceConfig(source: customSource)
    }
    
    private func createCustomDestination(
        id: String = "dest-1",
        name: String = "Test Destination",
        enabled: Bool = true
    ) -> Destination {
        let baseMock = SwiftTestMockProvider.mockSourceConfig.source.destinations.first!
        
        return Destination(
            destinationId: id,
            destinationName: name,
            isDestinationEnabled: enabled,
            destinationConfig: baseMock.destinationConfig,
            destinationDefinitionId: baseMock.destinationDefinitionId,
            destinationDefinition: baseMock.destinationDefinition,
            updatedAt: baseMock.updatedAt,
            shouldApplyDeviceModeTransformation: baseMock.shouldApplyDeviceModeTransformation,
            propagateEventsUntransformedOnError: baseMock.propagateEventsUntransformedOnError
        )
    }
}
