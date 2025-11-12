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
        #expect(enabledConfig.source.isSourceEnabled == true)
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: enabledConfig)
        
        #expect(result.source.isSourceEnabled == false)
    }
    
    @Test("given already disabled source config, when disabling, then remains disabled")
    func testDisableSourceConfigActionWorksOnAlreadyDisabledSource() {
        let disabledConfig = createCustomSourceConfig(isEnabled: false)
        #expect(disabledConfig.source.isSourceEnabled == false)
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: disabledConfig)
        
        #expect(result.source.isSourceEnabled == false)
        #expect(result.source.sourceId == disabledConfig.source.sourceId)
    }
    
    @Test("given source config with destinations, when disabling, then all other properties are preserved")
    func testDisableSourceConfigActionPreservesAllOtherProperties() {
        let destinations = [createCustomDestination(id: "dest-1", name: "Test Destination")]
        
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
        #expect(result.source.isSourceEnabled == false) // Only this should change
        #expect(result.source.workspaceId == "test-workspace-id")
        #expect(result.source.updatedAt == "2025-01-01T00:00:00.000Z")
        #expect(result.source.destinations.count == 1)
        #expect(result.source.destinations.first?.destinationId == "dest-1")
    }
    
    // MARK: - State Management Integration Tests
    
    @Test("given state instance, when dispatching disable action, then state updates correctly")
    func testDisableSourceConfigActionWithStateManagement() {
        let enabledConfig = createCustomSourceConfig(isEnabled: true)
        let stateInstance = createState(initialState: enabledConfig)
        
        let action = DisableSourceConfigAction()
        stateInstance.dispatch(action: action)
        
        let currentState = stateInstance.state.value
        #expect(currentState.source.isSourceEnabled == false)
        #expect(currentState.source.sourceId == enabledConfig.source.sourceId)
    }
    
    @Test("given subscribed state, when disabling config, then subscribers receive updates")
    func testDisableSourceConfigActionNotifiesSubscribers() {
        let enabledConfig = createCustomSourceConfig(isEnabled: true)
        let stateInstance = createState(initialState: enabledConfig)
        
        var receivedConfigs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        stateInstance.state.sink { config in
            receivedConfigs.append(config)
        }.store(in: &cancellables)
        
        let disableAction = DisableSourceConfigAction()
        
        stateInstance.dispatch(action: disableAction)
        stateInstance.dispatch(action: disableAction) // Should work idempotently
        
        #expect(receivedConfigs.count == 3) // Initial + 2 disable actions
        #expect(receivedConfigs[0].source.isSourceEnabled == true) // Initial
        #expect(receivedConfigs[1].source.isSourceEnabled == false) // First disable
        #expect(receivedConfigs[2].source.isSourceEnabled == false) // Second disable (idempotent)
    }
    
    // MARK: - Property Preservation Tests
    
    @Test("given various source configurations, when disabling, then only isSourceEnabled changes",
          arguments: [
            ("source-1", "Source One", "key-1", "workspace-1", "2025-01-01"),
            ("source-2", "Source Two", "key-2", "workspace-2", "2025-01-02"),
            ("", "", "", "", ""),
            ("special-🚀-id", "Special Source 🎯", "super-key-123", "workspace-special", "2025-12-31")
          ])
    func testDisableSourceConfigActionPreservesSpecificProperties(
        sourceId: String,
        sourceName: String,
        writeKey: String,
        workspaceId: String,
        updatedAt: String
    ) {
        let originalConfig = createCustomSourceConfig(
            sourceId: sourceId,
            sourceName: sourceName,
            writeKey: writeKey,
            isEnabled: true, // Always start enabled
            workspaceId: workspaceId,
            updatedAt: updatedAt
        )
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: originalConfig)
        
        #expect(result.source.sourceId == sourceId)
        #expect(result.source.sourceName == sourceName)
        #expect(result.source.writeKey == writeKey)
        #expect(result.source.isSourceEnabled == false) // Should always become false
        #expect(result.source.workspaceId == workspaceId)
        #expect(result.source.updatedAt == updatedAt)
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
    
    // MARK: - Edge Cases and Real-world Scenarios
    
    @Test("given config with multiple destinations, when disabling, then destinations are preserved")
    func testDisableSourceConfigActionPreservesMultipleDestinations() {
        let destination1 = createCustomDestination(id: "dest-1", name: "Destination 1")
        let destination2 = createCustomDestination(id: "dest-2", name: "Destination 2")
        let destination3 = createCustomDestination(id: "dest-3", name: "Destination 3")
        
        let configWithDestinations = createCustomSourceConfig(
            isEnabled: true,
            destinations: [destination1, destination2, destination3]
        )
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: configWithDestinations)
        
        #expect(result.source.isSourceEnabled == false)
        #expect(result.source.destinations.count == 3)
        #expect(result.source.destinations[0].destinationId == "dest-1")
        #expect(result.source.destinations[1].destinationId == "dest-2")
        #expect(result.source.destinations[2].destinationId == "dest-3")
    }
    
    @Test("given config with empty destinations, when disabling, then empty destinations are preserved")
    func testDisableSourceConfigActionPreservesEmptyDestinations() {
        let configWithoutDestinations = createCustomSourceConfig(
            isEnabled: true,
            destinations: []
        )
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: configWithoutDestinations)
        
        #expect(result.source.isSourceEnabled == false)
        #expect(result.source.destinations.isEmpty)
    }
    
    @Test("given initial state config, when disabling, then becomes disabled initial state")
    func testDisableSourceConfigActionWorksWithInitialState() {
        let initialConfig = SourceConfig.initialState()
        #expect(initialConfig.source.isSourceEnabled == true)
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: initialConfig)
        
        #expect(result.source.isSourceEnabled == false)
        #expect(result.source.sourceId == String.empty)
        #expect(result.source.destinations.isEmpty)
    }
    
    // MARK: - Error Response Simulation Tests
    
    @Test("given 404 error scenario simulation, when disabling source, then config is properly disabled")
    func testDisableSourceConfigActionSimulates404ErrorHandling() {
        let activeConfig = createCustomSourceConfig(
            sourceId: "active-source",
            isEnabled: true
        )
        
        let action = DisableSourceConfigAction()
        let result = action.reduce(currentState: activeConfig)
        
        #expect(result.source.isSourceEnabled == false)
        #expect(result.source.sourceId == "active-source") // Other properties preserved
    }
    
    @Test("given multiple consecutive disable actions, when applied, then remains idempotent")
    func testDisableSourceConfigActionIdempotency() {
        let enabledConfig = createCustomSourceConfig(isEnabled: true)
        let stateInstance = createState(initialState: enabledConfig)
        
        let action = DisableSourceConfigAction()
        
        stateInstance.dispatch(action: action) // First disable
        let firstResult = stateInstance.state.value
        
        stateInstance.dispatch(action: action) // Second disable
        let secondResult = stateInstance.state.value
        
        stateInstance.dispatch(action: action) // Third disable
        let thirdResult = stateInstance.state.value
        
        #expect(firstResult.source.isSourceEnabled == false)
        #expect(secondResult.source.isSourceEnabled == false)
        #expect(thirdResult.source.isSourceEnabled == false)
        
        #expect(firstResult.source.sourceId == secondResult.source.sourceId)
        #expect(secondResult.source.sourceId == thirdResult.source.sourceId)
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
}
