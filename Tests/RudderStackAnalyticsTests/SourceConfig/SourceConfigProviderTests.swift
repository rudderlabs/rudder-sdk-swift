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
    var sourceConfigProvider: SourceConfigProvider
    
    init() {
        self.mockStorage = MockStorage()
        self.analytics = MockProvider.createMockAnalytics(storage: mockStorage)
        self.sourceConfigProvider = SourceConfigProvider(analytics: analytics, backoffPolicy: ExponentialBackoffPolicy(minDelayInMillis: 0))
        MockURLProtocol.forwardGetRequestsToHandler = true
    }
    
    deinit {
        MockURLProtocol.forwardGetRequestsToHandler = false
        let storage = self.mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    @Test("when fetching cached config and no config exists, then does not notify observers")
    func testFetchCachedConfigNoConfig() {
        var receivedConfigs: [SourceConfig] = []
        let cancellable = analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
        
        defer { cancellable.cancel() }
        
        sourceConfigProvider.fetchCachedConfigAndNotifyObservers()
        
        #expect(receivedConfigs.count == 1)
        #expect(receivedConfigs.first?.source.sourceId.isEmpty == true)
    }
    
    @Test("when fetching cached config with valid stored config, then notifies observers")
    func testFetchCachedConfigValidConfig() {
        let storedConfig = _simpleSourceConfig
        mockStorage.write(value: storedConfig.jsonString, key: Constants.storageKeys.sourceConfig)
        
        var receivedConfigs: [SourceConfig] = []
        let cancellable = analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
        
        defer { cancellable.cancel() }
        
        sourceConfigProvider.fetchCachedConfigAndNotifyObservers()
        
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
    func testFetchCachedConfigCorruptedJSON() {
        
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
    
    @Test("given multiple observers, when SourceConfig is updated, then all observers are notified")
    func testMultipleObservers() {
        let storedConfig = _simpleSourceConfig
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
        
        sourceConfigProvider.fetchCachedConfigAndNotifyObservers()
        
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
    
    @Test("given a SourceConfig request returning HTTP 400 error, when refreshConfig is called, then handles invalidWriteKey without retries")
    func testHandleHTTP400InvalidWriteKey() {
        
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 400)
        
        let initialConfig = analytics.sourceConfigState.state.value
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            MockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.refreshConfigAndNotifyObservers()
        
        #expect(receivedConfig?.jsonString == initialConfig.jsonString)
        #expect(configUpdateCount == 1) // No update due to 400 error
    }
    
    @Test("given a SourceConfig request returning invalidWriteKey error, when refreshConfig is called, then shuts down analytics and clears storage")
    func testHandleInvalidWriteKeyError() async {
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 400)
        
        defer { MockProvider.teardownMockURLSession() }
        
        mockStorage.write(value: "test_user_data", key: "user_data")
        mockStorage.write(value: "cached_config_data", key: Constants.storageKeys.sourceConfig)
        
        sourceConfigProvider.refreshConfigAndNotifyObservers()
        
        await mockStorage.waitForKeyRemoval(key: Constants.storageKeys.sourceConfig)
        
        #expect(analytics.isAnalyticsShutdown, "Analytics should be shutdown after invalid write key error")
        #expect(analytics.isInvalidWriteKey, "Invalid write key flag should be set")
        #expect(!analytics.isAnalyticsActive, "Analytics should be inactive after shutdown")
        
        let clearedUserData: String? = self.mockStorage.read(key: "user_data")
        let clearedSourceConfig: String? = self.mockStorage.read(key: Constants.storageKeys.sourceConfig)
        
        #expect(clearedUserData == nil, "User data should be cleared after invalid write key error")
        #expect(clearedSourceConfig == nil, "Source config should be cleared after invalid write key error")
    }
    
    @Test("given a SourceConfig request returning success after a failure, when refreshConfig is called, then eventually succeeds with valid config")
    func testHandleSuccessAfterRetries() async {
        MockProvider.setupMockURLSession()
        HttpNetwork.session = prepareMockUrlSessionWithEventualSuccess(failureCount: 1)
        
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        let expectedConfig = MockProvider.sourceConfiguration
        
        defer {
            cancellables.removeAll()
            MockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.refreshConfigAndNotifyObservers()
        
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig, expectedValue: expectedConfig?.jsonString)
        
        #expect(receivedConfig?.source.sourceId == expectedConfig?.source.sourceId)
        #expect(configUpdateCount == 2) // Initial state + successful update
    }
    
    @Test("given storage has a valid cached source config, when fetchCachedConfig and refreshConfig are called, then both complete successfully")
    func testCachedAndRefreshIntegration() async {
        let mockConfig = MockProvider.sourceConfiguration
        mockStorage.write(value: mockConfig?.jsonString, key: Constants.storageKeys.sourceConfig)
        
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 200)
        
        var receivedConfigs: [SourceConfig] = []
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            MockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfigs.append(config)
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.fetchCachedConfigAndNotifyObservers() // Should load from cache
        sourceConfigProvider.refreshConfigAndNotifyObservers() // Should attempt network fetch
        
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig)
        
        #expect(receivedConfigs.count >= 2) // Initial + cached config, possibly + network attempt
        
        if receivedConfigs.count >= 2 {
            let cachedConfig = receivedConfigs[1]
            #expect(cachedConfig.source.sourceId == mockConfig?.source.sourceId)
        }
    }
    
    @Test("given a SourceConfig request returning HTTP 500 error, when refreshConfig is called, then retries with exponential backoff until max attempts")
    func testHandleHTTP500WithRetries() async {
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 500)
        
        let initialConfig = analytics.sourceConfigState.state.value
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            MockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.state
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
                
        // When
        sourceConfigProvider.refreshConfigAndNotifyObservers()
        
        await runAfter(0.1) {
            #expect(receivedConfig?.jsonString == initialConfig.jsonString)
            #expect(configUpdateCount == 1)
        }
    }
    
    @Test("given timeout HttpNetworkError, when converting to SourceConfigResult, then returns timeout error")
    func testTimeoutErrorMapsToSourceConfigTimeout() {
        let result: Result<Data, Error> = .failure(HttpNetworkError.timeout)
        let configResult = result.sourceConfigResult

        if case .failure(let error) = configResult {
            #expect(error == .timeout)
        } else {
            Issue.record("Expected SourceConfigError.timeout")
        }
    }
}

// MARK: - Helpers
extension SourceConfigProviderTests {
    
    private var _defaultHeaders: [String: String] { ["Content-Type": "application/json"] }
    
    private var _simpleSourceConfig: SourceConfig {
        return SourceConfig(
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
    }
    
    private func prepareMockUrlSessionWithEventualSuccess(failureCount: Int) -> URLSession {
        var attemptCount = 0
        
        MockURLProtocol.requestHandler = { [self] _ in
            attemptCount += 1
            if attemptCount <= failureCount {
                // Return 500 error for first few attempts
                let json = ["error": "Server error", "code": 500]
                let data = json.jsonString?.utf8Data
                return (500, data, _defaultHeaders)
            } else {
                // Return success after failure count is reached
                let json = MockProvider.sourceConfigurationDictionary ?? [:]
                let data = json.jsonString?.utf8Data
                return (200, data, _defaultHeaders)
            }
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
