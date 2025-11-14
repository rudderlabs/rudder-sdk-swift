//
//  DisableSourceConfigActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 12/11/25.
//

import Testing
import Combine
@testable import RudderStackAnalytics

@Suite("DisableSourceConfigAction Tests")
struct DisableSourceConfigActionTests {
    
    // MARK: - Basic Functionality Tests
    
    @Test("given enabled source config, when disabling, then isSourceEnabled becomes false")
    func testDisableSourceConfigActionSetsEnabledToFalse() {
        let enabledConfig = createCustomSourceConfig(isEnabled: true)
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: enabledConfig)
        
        #expect(!result.source.isSourceEnabled)
    }
    
    @Test("given already disabled source config, when disabling, then remains disabled")
    func testDisableSourceConfigActionWorksOnAlreadyDisabledSource() {
        let disabledConfig = createCustomSourceConfig(isEnabled: false)
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: disabledConfig)
        
        #expect(!result.source.isSourceEnabled)
        #expect(result.source.sourceId == disabledConfig.source.sourceId)
    }
    
    @Test("given source config with destinations, when disabling, then all other properties are preserved")
    func testDisableSourceConfigActionPreservesAllOtherProperties() {
        let destinations = [createCustomDestination(id: customDestinationId, name: "Test Destination")]
        
        let originalConfig = createCustomSourceConfig(
            sourceId: "test-source-id",
            sourceName: "Test Source Name",
            writeKey: "test-write-key",
            isEnabled: true,
            workspaceId: "test-workspace-id",
            updatedAt: "2025-01-01T00:00:00.000Z",
            destinations: destinations
        )
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: originalConfig)
        
        #expect(result.source.sourceId == "test-source-id")
        #expect(result.source.sourceName == "Test Source Name")
        #expect(result.source.writeKey == "test-write-key")
        #expect(!result.source.isSourceEnabled)
        #expect(result.source.workspaceId == "test-workspace-id")
        #expect(result.source.updatedAt == "2025-01-01T00:00:00.000Z")
        #expect(result.source.destinations.count == 1)
        #expect(result.source.destinations.first?.destinationId == customDestinationId)
    }
    
    // MARK: - State Management Integration Tests
    
    @Test("given state instance, when dispatching disable action, then state updates correctly")
    func testDisableSourceConfigActionWithStateManagement() {
        let enabledConfig = createCustomSourceConfig(isEnabled: true)
        let stateInstance = createState(initialState: enabledConfig)
        
        let action = DisableSourceConfigAction()
        stateInstance.dispatch(action: action)
        
        let currentState = stateInstance.state.value
        #expect(!currentState.source.isSourceEnabled)
        #expect(currentState.source.sourceId == enabledConfig.source.sourceId)
    }
    
    // MARK: - Immutability Tests
    
    @Test("given original config, when applying disable action, then original config remains unchanged")
    func testDisableSourceConfigActionMaintainsImmutability() {
        let originalConfig = createCustomSourceConfig(isEnabled: true)
        let originalEnabledState = originalConfig.source.isSourceEnabled
        let originalSourceId = originalConfig.source.sourceId
        
        let action = DisableSourceConfigAction()
        _ = action.reduce(currentState: originalConfig)
        
        #expect(originalConfig.source.isSourceEnabled == originalEnabledState)
        #expect(originalConfig.source.sourceId == originalSourceId)
    }
}

// MARK: - Test Data Helpers using SwiftTestMockProvider
extension DisableSourceConfigActionTests {
    
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
    
    private var customDestinationId: String { "dest-1" }
}
