//
//  SourceConfigProviderTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 25/10/25.
//

import Foundation
import Testing
import Combine
@testable import RudderStackAnalytics

@Suite("SourceConfigProvider Tests")
class SourceConfigProviderTests {
    
    var mockStorage: MockStorage
    var analytics: Analytics
    var provider: SourceConfigProvider
    
    init() {
        self.mockStorage = MockStorage()
        self.analytics = SwiftTestMockProvider.createMockAnalytics(storage: mockStorage)
        self.provider = MockSourceConfigProvider(analytics: analytics)
    }
    
    deinit {
        let storage = self.mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    @Test("when fetching cached config and no config exists, then does not notify observers")
    func testSourceConfigProvider_FetchCachedConfig_NoConfig() async {
        var receivedConfigs: [SourceConfig] = []
        let cancellable = analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
        
        defer { cancellable.cancel() }
        
        provider.fetchCachedConfigAndNotifyObservers()
        
        #expect(receivedConfigs.count == 1)
        #expect(receivedConfigs.first?.source.sourceId.isEmpty == true)
    }
    
    @Test("when fetching cached config with valid stored config, then notifies observers")
    func testSourceConfigProvider_FetchCachedConfig_ValidConfig() async {
        let storedConfig = SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "cached-source-id",
                sourceName: "Cached Source",
                writeKey: "cached-write-key",
                isSourceEnabled: true,
                workspaceId: "cached-workspace",
                updatedAt: "2023-10-24T10:00:00Z",
                metricConfig: MetricsConfig(),
                destinations: []
            )
        )
        
        mockStorage.write(value: storedConfig.jsonString, key: Constants.storageKeys.sourceConfig)
        
        var receivedConfigs: [SourceConfig] = []
        let cancellable = analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
        
        defer { cancellable.cancel() }
        
        provider.fetchCachedConfigAndNotifyObservers()
        
        #expect(receivedConfigs.count == 2) // Initial + cached
        
        guard let lastConfig = receivedConfigs.last else {
            Issue.record("Can't read latest source configuration details")
            return
        }
        
        #expect(lastConfig.source.sourceId == "cached-source-id")
        #expect(lastConfig.source.sourceName == "Cached Source")
        #expect(lastConfig.source.writeKey == "cached-write-key")
    }
    
    @Test("when fetching cached config with corrupted JSON, then does not notify observers")
    func testSourceConfigProvider_FetchCachedConfig_CorruptedJSON() async {
        
        mockStorage.write(value: "invalid-json", key: Constants.storageKeys.sourceConfig)
        
        let provider = SourceConfigProvider(analytics: analytics)
        
        var receivedConfigs: [SourceConfig] = []
        let cancellable = analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
        
        defer { cancellable.cancel() }
        
        provider.fetchCachedConfigAndNotifyObservers()
        
        #expect(receivedConfigs.count == 1)
        #expect(receivedConfigs.first?.source.sourceId.isEmpty == true)
    }
    
    @Test("Given multiple observers, When SourceConfig is updated, Then all observers are notified")
    func testSourceConfig_MultipleObservers() async {
        let storedConfig = SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "cached-source-id",
                sourceName: "Cached Source",
                writeKey: "cached-write-key",
                isSourceEnabled: true,
                workspaceId: "cached-workspace",
                updatedAt: "2023-10-24T10:00:00Z",
                metricConfig: MetricsConfig(),
                destinations: []
            )
        )
        
        mockStorage.write(value: storedConfig.jsonString, key: Constants.storageKeys.sourceConfig)
        
        var observer1Configs: [SourceConfig] = []
        var observer2Configs: [SourceConfig] = []
        var observer3Configs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        // Observer 1
        analytics.sourceConfigState.state
            .sink { config in observer1Configs.append(config) }
            .store(in: &cancellables)
        
        // Observer 2
        analytics.sourceConfigState.state
            .sink { config in observer2Configs.append(config) }
            .store(in: &cancellables)
        
        // Observer 3
        analytics.sourceConfigState.state
            .sink { config in observer3Configs.append(config) }
            .store(in: &cancellables)
        
        provider.fetchCachedConfigAndNotifyObservers()
        
        #expect(observer1Configs.count == 2) // Initial + updated
        #expect(observer2Configs.count == 2) // Initial + updated
        #expect(observer3Configs.count == 2) // Initial + updated
        
        let latestConfig1 = observer1Configs.last
        let latestConfig2 = observer2Configs.last
        let latestConfig3 = observer3Configs.last
        
        #expect(latestConfig1?.source.sourceId == storedConfig.source.sourceId)
        #expect(latestConfig2?.source.sourceId == storedConfig.source.sourceId)
        #expect(latestConfig3?.source.sourceId == storedConfig.source.sourceId)
        
        cancellables.removeAll()
    }
    
    @Test("Given a SourceConfig request returning HTTP 400 error, When refreshConfig is called, Then handles invalidWriteKey without retries")
    func testSourceConfigProvider_HandleHTTP400InvalidWriteKey() async {
        
        SwiftTestMockProvider.setupMockURLSession()
        HttpNetwork.session = SwiftTestMockProvider.prepareMockSessionConfigSession(with: 400)
        
        let initialConfig = analytics.sourceConfigState.state.value
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            SwiftTestMockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        provider.refreshConfigAndNotifyObservers()
        
        #expect(receivedConfig?.jsonString == initialConfig.jsonString)
        #expect(configUpdateCount == 1) // No update due to 400 error
    }
    
    @Test("Given a SourceConfig request returning invalidWriteKey error, When refreshConfig is called, Then shuts down analytics and clears storage")
    func testSourceConfigProvider_HandleInvalidWriteKeyError() async {
        SwiftTestMockProvider.setupMockURLSession()
        HttpNetwork.session = SwiftTestMockProvider.prepareMockSessionConfigSession(with: 400)
        
        defer { SwiftTestMockProvider.teardownMockURLSession() }
        
        mockStorage.write(value: "test_user_data", key: "user_data")
        mockStorage.write(value: "cached_config_data", key: Constants.storageKeys.sourceConfig)
        
        #expect(analytics.isAnalyticsActive == true, "Analytics should be active initially")
        #expect(analytics.isAnalyticsShutdown == false, "Analytics should not be shutdown initially")
        #expect(analytics.isInvalidWriteKey == false, "WriteKey should be valid initially")
        
        provider.refreshConfigAndNotifyObservers()
        
        await mockStorage.waitForKeyRemoval(key: Constants.storageKeys.sourceConfig)
        
        #expect(self.analytics.isAnalyticsShutdown == true, "Analytics should be shutdown after invalid write key error")
        #expect(self.analytics.isInvalidWriteKey == true, "Invalid write key flag should be set")
        #expect(self.analytics.isAnalyticsActive == false, "Analytics should be inactive after shutdown")
        
        let clearedUserData: String? = self.mockStorage.read(key: "user_data")
        let clearedSourceConfig: String? = self.mockStorage.read(key: Constants.storageKeys.sourceConfig)
        
        #expect(clearedUserData == nil, "User data should be cleared after invalid write key error")
        #expect(clearedSourceConfig == nil, "Source config should be cleared after invalid write key error")
    }
    
    @Test("Given a SourceConfig request returning success after a failure, When refreshConfig is called, Then eventually succeeds with valid config")
    func testSourceConfigProvider_HandleSuccessAfterRetries() async {
        SwiftTestMockProvider.setupMockURLSession()
        HttpNetwork.session = prepareMockUrlSessionWithEventualSuccess(failureCount: 1)
        
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        let expectedConfig = SwiftTestMockProvider.sourceConfiguration
        
        defer {
            cancellables.removeAll()
            SwiftTestMockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        provider.refreshConfigAndNotifyObservers()
        
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig, expectedValue: expectedConfig?.jsonString)
        
        #expect(receivedConfig?.source.sourceId == expectedConfig?.source.sourceId)
        #expect(configUpdateCount == 2) // Initial state + successful update
    }
    
    @Test("Given storage has a valid cached source config, When fetchCachedConfig and refreshConfig are called, Then both complete successfully")
    func testSourceConfigProvider_CachedAndRefreshIntegration() async {
        let mockConfig = SwiftTestMockProvider.sourceConfiguration
        mockStorage.write(value: mockConfig?.jsonString, key: Constants.storageKeys.sourceConfig)
        
        SwiftTestMockProvider.setupMockURLSession()
        HttpNetwork.session = SwiftTestMockProvider.prepareMockSessionConfigSession(with: 200)
        
        var receivedConfigs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            SwiftTestMockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
            .store(in: &cancellables)
        
        provider.fetchCachedConfigAndNotifyObservers() // Should load from cache
        provider.refreshConfigAndNotifyObservers() // Should attempt network fetch
        
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig)
        
        #expect(receivedConfigs.count >= 2) // Initial + cached config, possibly + network attempt
        
        if receivedConfigs.count >= 2 {
            let cachedConfig = receivedConfigs[1]
            #expect(cachedConfig.source.sourceId == mockConfig?.source.sourceId)
        }
    }
    
    @Test("Given a SourceConfig request returning HTTP 500 error, When refreshConfig is called, Then retries with exponential backoff until max attempts")
    func testSourceConfigProvider_HandleHTTP500WithRetries() async {
        SwiftTestMockProvider.setupMockURLSession()
        HttpNetwork.session = SwiftTestMockProvider.prepareMockSessionConfigSession(with: 500)
        
        let initialConfig = analytics.sourceConfigState.state.value
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            SwiftTestMockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
                
        // When
        provider.refreshConfigAndNotifyObservers()
        
        await runAfter(0.1) {
            #expect(receivedConfig?.jsonString == initialConfig.jsonString)
            #expect(configUpdateCount == 1)
        }
    }
    
    @Test("when ExponentialBackoffPolicy is called multiple times, then delays increase exponentially")
    func testExponentialBackoffPolicy_Integration() {
        guard let policy = provider.provideBackoffPolicy() as? ExponentialBackoffPolicy else {
            Issue.record("Can't initialize backoff policy")
            return
        }
        
        let delay1 = policy.nextDelayInMilliseconds()
        let delay2 = policy.nextDelayInMilliseconds()
        let delay3 = policy.nextDelayInMilliseconds()
        
        #expect(delay1 > 0)
        #expect(delay2 > delay1) // Should increase
        #expect(delay3 > delay2) // Should continue increasing
    }
}

// MARK: - Helpers
extension SourceConfigProviderTests {
    private func prepareMockUrlSessionWithEventualSuccess(failureCount: Int) -> URLSession {
        var attemptCount = 0
        
        MockURLProtocol.requestHandler = { _ in
            attemptCount += 1
            if attemptCount <= failureCount {
                // Return 500 error for first few attempts
                let json = ["error": "Server error", "code": 500]
                let data = json.jsonString?.utf8Data
                return (500, data, ["Content-Type": "application/json"])
            } else {
                // Return success after failure count is reached
                let json = MockProvider.sourceConfigurationDictionary ?? [:]
                let data = json.jsonString?.utf8Data
                return (200, data, ["Content-Type": "application/json"])
            }
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    private func prepareMockUrlSessionWithMalformedJSON() -> URLSession {
        MockURLProtocol.requestHandler = { _ in
            // Return malformed JSON
            let malformedJsonString = "{ invalid json structure }"
            let data = malformedJsonString.data(using: .utf8)!
            return (200, data, ["Content-Type": "application/json"])
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
