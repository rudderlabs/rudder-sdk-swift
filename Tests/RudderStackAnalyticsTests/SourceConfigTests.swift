//
//  SourceConfigTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/09/25.
//

import Testing
import Combine

@testable import RudderStackAnalytics

struct SourceConfigTests {
    
    @Test("Given cached SourceConfig exists, When fetchCachedConfigAndNotifyObservers is called, Then observers are notified")
    func testFetchCachedConfigAndNotifyObservers_CachedConfigExists() async throws {
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
    }
}

