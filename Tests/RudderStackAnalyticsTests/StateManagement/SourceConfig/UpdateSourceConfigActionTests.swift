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
        let currentConfig = createCustomSourceConfig(sourceId: "current-id", sourceName: "Current Source", isEnabled: false)
        
        let newConfig = createCustomSourceConfig(sourceId: "new-id", sourceName: "New Source", isEnabled: true)
        
        let action = UpdateSourceConfigAction(updatedSourceConfig: newConfig)
        let result = action.reduce(currentState: currentConfig)
        
        #expect(result.source.sourceId == "new-id")
        #expect(result.source.sourceName == "New Source")
        #expect(result.source.isSourceEnabled)
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
        #expect(currentState.source.isSourceEnabled)
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
}

// MARK: - Test Data Helpers using MockProvider

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
        let baseMock = MockProvider.mockSourceConfig
        
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
        id: String,
        name: String,
        enabled: Bool = true
    ) -> Destination {
        let baseMock = MockProvider.mockSourceConfig.source.destinations.first!
        
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
