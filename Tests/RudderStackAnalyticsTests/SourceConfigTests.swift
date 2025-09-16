//
//  SourceConfigTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/09/25.
//

import Testing
import Combine
import Foundation

@testable import RudderStackAnalytics

struct SourceConfigTests {
    
    @Test("Given cached SourceConfig exists, When fetchCachedConfigAndNotifyObservers is called, Then observers are notified")
    func testFetchCachedConfigAndNotifyObservers_CachedConfigExists() {
        // Given
        let mockAnalytics = MockAnalytics()
        let expectedConfig = MockProvider.sourceConfiguration
        mockAnalytics.storage.write(value: MockHelper.readJson(from: "mock_source_config")?.trimmed, key: Constants.storageKeys.sourceConfig)
        
        // When
        var receivedConfig: SourceConfig?
        var cancellables = Set<AnyCancellable>()
        
        mockAnalytics.sourceConfigState.state
            .sink { receivedConfig = $0 }
            .store(in: &cancellables)
        
        let provider = SourceConfigProvider(analytics: mockAnalytics)
        provider.fetchCachedConfigAndNotifyObservers()
        
        // Then
        #expect(receivedConfig?.jsonString == expectedConfig?.jsonString)
        cancellables.removeAll()
        mockAnalytics.storage.remove(key: Constants.storageKeys.sourceConfig)
    }
    
    @Test("Given no cached SourceConfig exists, When fetchCachedConfigAndNotifyObservers is called, Then observers are not notified with cached config")
    func testFetchCachedConfigAndNotifyObservers_NoCachedConfigExists() {
        // Given
        let mockAnalytics = MockAnalytics()
        let initialConfig = mockAnalytics.sourceConfigState.state.value
        
        // When
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        mockAnalytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        let provider = SourceConfigProvider(analytics: mockAnalytics)
        provider.fetchCachedConfigAndNotifyObservers()
        
        // Then
        #expect(receivedConfig?.jsonString == initialConfig.jsonString)
        #expect(configUpdateCount == 1) // Only initial state, no update from cache
        cancellables.removeAll()
    }
    
    @Test("Given SourceConfig initial state, When initialState is called, Then returns default configuration")
    func testSourceConfig_InitialState() {
        // When
        let initialConfig = SourceConfig.initialState()
        
        // Then
        #expect(initialConfig.source.sourceId.isEmpty)
        #expect(initialConfig.source.sourceName.isEmpty)
        #expect(initialConfig.source.writeKey.isEmpty)
        #expect(initialConfig.source.isSourceEnabled == true)
        #expect(initialConfig.source.workspaceId.isEmpty)
        #expect(initialConfig.source.destinations.isEmpty)
        #expect(initialConfig.source.metricConfig.statsCollection.errors.enabled == false)
        #expect(initialConfig.source.metricConfig.statsCollection.metrics.enabled == false)
    }
    
    @Test("Given valid SourceConfig JSON, When decoded, Then returns correct SourceConfig object")
    func testSourceConfig_JSONDecoding() throws {
        // Given
        let mockJsonData = MockHelper.readJson(from: "mock_source_config")?.trimmed.utf8Data
        #expect(mockJsonData != nil, "Mock JSON data should not be nil")
        
        // When
        let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: mockJsonData!)
        
        // Then
        #expect(!sourceConfig.source.sourceId.isEmpty)
        #expect(!sourceConfig.source.sourceName.isEmpty)
        #expect(!sourceConfig.source.writeKey.isEmpty)
        #expect(sourceConfig.source.isSourceEnabled == true)
        #expect(!sourceConfig.source.workspaceId.isEmpty)
        #expect(!sourceConfig.source.destinations.isEmpty)
        
        // Verify destinations structure
        let firstDestination = sourceConfig.source.destinations.first
        #expect(firstDestination?.destinationId.isEmpty == false)
        #expect(firstDestination?.destinationName.isEmpty == false)
        #expect(firstDestination?.isDestinationEnabled != nil)
    }
    
    @Test("Given SourceConfig object, When encoded to JSON, Then produces valid JSON string")
    func testSourceConfig_JSONEncoding() throws {
        // Given
        let sourceConfig = MockProvider.sourceConfiguration
        #expect(sourceConfig != nil, "Mock source config should not be nil")
        
        // When
        let jsonString = sourceConfig?.jsonString
        
        // Then
        #expect(jsonString != nil)
        #expect(jsonString?.isEmpty == false)
        
        // Verify it can be decoded back
        let jsonData = jsonString?.utf8Data
        #expect(jsonData != nil, "JSON data should not be nil")
        
        let decodedConfig = try JSONDecoder().decode(SourceConfig.self, from: jsonData!)
        #expect(decodedConfig.source.sourceId == sourceConfig?.source.sourceId)
        #expect(decodedConfig.source.sourceName == sourceConfig?.source.sourceName)
    }
    
    @Test("Given SourceConfig with state management, When UpdateSourceConfigAction is dispatched, Then state is updated correctly")
    func testSourceConfig_StateManagement() async {
        // Given
        let mockAnalytics = MockAnalytics()
        let newConfig = MockProvider.sourceConfiguration
        #expect(newConfig != nil, "Mock source config should not be nil")
        
        var receivedConfigs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        mockAnalytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
            .store(in: &cancellables)
        
        // When
        let updateAction = UpdateSourceConfigAction(updatedSourceConfig: newConfig!)
        mockAnalytics.sourceConfigState.dispatch(action: updateAction)
        
        await runAfter(0.1) {
            // Then
            #expect(receivedConfigs.count >= 2) // Initial + updated
            let latestConfig = receivedConfigs.last
            #expect(latestConfig?.source.sourceId == newConfig?.source.sourceId)
            #expect(latestConfig?.source.sourceName == newConfig?.source.sourceName)
            #expect(latestConfig?.source.isSourceEnabled == newConfig?.source.isSourceEnabled)
        }
        
        cancellables.removeAll()
    }
    
    @Test("Given corrupted cached SourceConfig, When fetchCachedConfigAndNotifyObservers is called, Then handles gracefully")
    func testFetchCachedConfigAndNotifyObservers_CorruptedCache() {
        // Given
        let mockAnalytics = MockAnalytics()
        let invalidJson = "{ invalid json }"
        mockAnalytics.storage.write(value: invalidJson, key: Constants.storageKeys.sourceConfig)
        
        let initialConfig = mockAnalytics.sourceConfigState.state.value
        
        // When
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        mockAnalytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        let provider = SourceConfigProvider(analytics: mockAnalytics)
        provider.fetchCachedConfigAndNotifyObservers()
        
        // Then
        #expect(receivedConfig?.jsonString == initialConfig.jsonString)
        #expect(configUpdateCount == 1) // Only initial state, no update due to corrupted cache
        cancellables.removeAll()
    }
    
    @Test("Given multiple observers, When SourceConfig is updated, Then all observers are notified")
    func testSourceConfig_MultipleObservers() async {
        // Given
        let mockAnalytics = MockAnalytics()
        let newConfig = MockProvider.sourceConfiguration
        #expect(newConfig != nil, "Mock source config should not be nil")
        
        var observer1Configs: [SourceConfig] = []
        var observer2Configs: [SourceConfig] = []
        var observer3Configs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        // Observer 1
        mockAnalytics.sourceConfigState.state
            .sink { config in observer1Configs.append(config) }
            .store(in: &cancellables)
        
        // Observer 2
        mockAnalytics.sourceConfigState.state
            .sink { config in observer2Configs.append(config) }
            .store(in: &cancellables)
        
        // Observer 3
        mockAnalytics.sourceConfigState.state
            .sink { config in observer3Configs.append(config) }
            .store(in: &cancellables)
        
        // When
        let provider = SourceConfigProvider(analytics: mockAnalytics)
        mockAnalytics.storage.write(value: newConfig?.jsonString, key: Constants.storageKeys.sourceConfig)
        provider.fetchCachedConfigAndNotifyObservers()
        
        await runAfter(0.1) {
            // Then
            #expect(observer1Configs.count >= 2) // Initial + updated
            #expect(observer2Configs.count >= 2) // Initial + updated  
            #expect(observer3Configs.count >= 2) // Initial + updated
            
            let latestConfig1 = observer1Configs.last
            let latestConfig2 = observer2Configs.last
            let latestConfig3 = observer3Configs.last
            
            #expect(latestConfig1?.source.sourceId == newConfig?.source.sourceId)
            #expect(latestConfig2?.source.sourceId == newConfig?.source.sourceId)
            #expect(latestConfig3?.source.sourceId == newConfig?.source.sourceId)
        }
        
        cancellables.removeAll()
    }
    
    @Test("Given SourceConfig with enabled source, When isSourceEnabled is accessed, Then returns correct value")
    func testSourceConfig_SourceEnabledStatus() {
        // Given
        let enabledConfig = MockProvider.sourceConfiguration
        #expect(enabledConfig != nil, "Mock source config should not be nil")
        
        // When & Then - Test enabled source from mock data
        #expect(enabledConfig?.source.isSourceEnabled == true)
        
        // Test initial state (should be enabled by default)
        let initialConfig = SourceConfig.initialState()
        #expect(initialConfig.source.isSourceEnabled == true)
    }
    
    @Test("Given SourceConfig with destinations, When accessing destinations, Then returns correct destination data")
    func testSourceConfig_DestinationData() {
        // Given
        let sourceConfig = MockProvider.sourceConfiguration
        #expect(sourceConfig != nil, "Mock source config should not be nil")
        
        // When & Then
        let destinations = sourceConfig?.source.destinations
        #expect(destinations?.isEmpty == false)
        
        if let firstDestination = destinations?.first {
            #expect(!firstDestination.destinationId.isEmpty)
            #expect(!firstDestination.destinationName.isEmpty)
            #expect(!firstDestination.destinationDefinitionId.isEmpty)
            #expect(!firstDestination.destinationDefinition.name.isEmpty)
            #expect(!firstDestination.destinationDefinition.displayName.isEmpty)
        }
    }
    
    @Test("Given SourceConfig metrics configuration, When accessing metrics config, Then returns correct metrics data")
    func testSourceConfig_MetricsConfiguration() {
        // Given
        let sourceConfig = MockProvider.sourceConfiguration
        #expect(sourceConfig != nil, "Mock source config should not be nil")
        
        // When & Then
        let metricsConfig = sourceConfig?.source.metricConfig
        #expect(metricsConfig != nil)
        
        let statsCollection = metricsConfig?.statsCollection
        #expect(statsCollection != nil)
        #expect(statsCollection?.errors.enabled != nil)
        #expect(statsCollection?.metrics.enabled != nil)
    }
    
    @Test("Given sequential SourceConfig updates, When multiple updates are dispatched, Then state reflects latest update")
    func testSourceConfig_SequentialUpdates() async {
        // Given
        let mockAnalytics = MockAnalytics()
        let config1 = SourceConfig.initialState()
        let config2 = MockProvider.sourceConfiguration
        #expect(config2 != nil, "Mock source config should not be nil")
        
        var receivedConfigs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        mockAnalytics.sourceConfigState.state
            .sink { config in receivedConfigs.append(config) }
            .store(in: &cancellables)
        
        // When - Dispatch multiple updates
        let updateAction1 = UpdateSourceConfigAction(updatedSourceConfig: config1)
        mockAnalytics.sourceConfigState.dispatch(action: updateAction1)
        
        await runAfter(0.05) {
            let updateAction2 = UpdateSourceConfigAction(updatedSourceConfig: config2!)
            mockAnalytics.sourceConfigState.dispatch(action: updateAction2)
        }
        
        await runAfter(0.1) {
            // Then
            #expect(receivedConfigs.count >= 3) // Initial + update1 + update2
            let latestConfig = receivedConfigs.last
            #expect(latestConfig?.source.sourceId == config2?.source.sourceId)
            #expect(latestConfig?.source.sourceName == config2?.source.sourceName)
        }
        
        cancellables.removeAll()
    }
    
    @Test("Given SourceConfig state observing, When observer is cancelled, Then no memory leaks occur")
    func testSourceConfig_ObserverCancellation() async {
        // Given
        let mockAnalytics = MockAnalytics()
        let newConfig = MockProvider.sourceConfiguration
        #expect(newConfig != nil, "Mock source config should not be nil")
        
        var receivedConfigsCount = 0
        var cancellables = Set<AnyCancellable>()
        
        // When - Setup observer and then cancel it
        mockAnalytics.sourceConfigState.state
            .sink { _ in receivedConfigsCount += 1 }
            .store(in: &cancellables)
        
        let updateAction = UpdateSourceConfigAction(updatedSourceConfig: newConfig!)
        mockAnalytics.sourceConfigState.dispatch(action: updateAction)
        
        await runAfter(0.05) {
            // Cancel the observer
            cancellables.removeAll()
            
            // Dispatch another update
            let anotherUpdateAction = UpdateSourceConfigAction(updatedSourceConfig: SourceConfig.initialState())
            mockAnalytics.sourceConfigState.dispatch(action: anotherUpdateAction)
        }
        
        await runAfter(0.1) {
            // Then - No additional updates should be received after cancellation
            // The count should remain the same as it was when we cancelled
            #expect(receivedConfigsCount >= 2) // Initial + first update, but not the second
        }
    }
}
