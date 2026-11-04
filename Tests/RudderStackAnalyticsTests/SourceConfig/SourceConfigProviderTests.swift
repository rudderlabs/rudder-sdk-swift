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
        let cancellable = analytics.sourceConfigState.publisher
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
        let cancellable = analytics.sourceConfigState.publisher
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
        let cancellable = analytics.sourceConfigState.publisher
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
        let observerLock = NSLock()
        var cancellables = Set<AnyCancellable>()
        
        // Observer 1
        analytics.sourceConfigState.publisher
            .sink { config in
                observerLock.lock()
                observer1Configs.append(config)
                observerLock.unlock()
            }
            .store(in: &cancellables)
        
        // Observer 2
        analytics.sourceConfigState.publisher
            .sink { config in
                observerLock.lock()
                observer2Configs.append(config)
                observerLock.unlock()
            }
            .store(in: &cancellables)
        
        // Observer 3
        analytics.sourceConfigState.publisher
            .sink { config in
                observerLock.lock()
                observer3Configs.append(config)
                observerLock.unlock()
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.fetchCachedConfigAndNotifyObservers()

        observerLock.lock()
        let observer1Snapshot = observer1Configs
        let observer2Snapshot = observer2Configs
        let observer3Snapshot = observer3Configs
        observerLock.unlock()

        #expect(observer1Snapshot.count == 2) // Initial + updated
        #expect(observer2Snapshot.count == 2) // Initial + updated
        #expect(observer3Snapshot.count == 2) // Initial + updated
        
        let latestConfig1 = observer1Snapshot.last
        let latestConfig2 = observer2Snapshot.last
        let latestConfig3 = observer3Snapshot.last
        
        #expect(latestConfig1?.source.sourceId == storedConfig.source.sourceId)
        #expect(latestConfig2?.source.sourceId == storedConfig.source.sourceId)
        #expect(latestConfig3?.source.sourceId == storedConfig.source.sourceId)
        
        cancellables.removeAll()
    }
    
    @Test("given a SourceConfig request returning HTTP 400 error, when the launch fetch runs, then handles invalidWriteKey without retries")
    func testHandleHTTP400InvalidWriteKey() {
        
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 400)
        
        let initialConfig = analytics.sourceConfigState.value
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            MockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.publisher
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.fetchConfigAtLaunchAndNotifyObservers()
        
        #expect(receivedConfig?.jsonString == initialConfig.jsonString)
        #expect(configUpdateCount == 1) // No update due to 400 error
    }
    
    @Test("given a SourceConfig request returning invalidWriteKey error, when the launch fetch runs, then shuts down analytics and clears storage")
    func testHandleInvalidWriteKeyError() async {
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 400)
        
        defer { MockProvider.teardownMockURLSession() }
        
        mockStorage.write(value: "test_user_data", key: "user_data")
        mockStorage.write(value: "cached_config_data", key: Constants.storageKeys.sourceConfig)
        
        sourceConfigProvider.fetchConfigAtLaunchAndNotifyObservers()
        
        await mockStorage.waitForKeyRemoval(key: Constants.storageKeys.sourceConfig)
        
        #expect(analytics.isAnalyticsShutdown, "Analytics should be shutdown after invalid write key error")
        #expect(analytics.isInvalidWriteKey, "Invalid write key flag should be set")
        #expect(!analytics.isAnalyticsActive, "Analytics should be inactive after shutdown")
        
        let clearedUserData: String? = self.mockStorage.read(key: "user_data")
        let clearedSourceConfig: String? = self.mockStorage.read(key: Constants.storageKeys.sourceConfig)
        
        #expect(clearedUserData == nil, "User data should be cleared after invalid write key error")
        #expect(clearedSourceConfig == nil, "Source config should be cleared after invalid write key error")
    }
    
    @Test("given a SourceConfig request returning success after a failure, when the launch fetch runs, then eventually succeeds with valid config")
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
        
        analytics.sourceConfigState.publisher
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.fetchConfigAtLaunchAndNotifyObservers()
        
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig, expectedValue: expectedConfig?.jsonString)
        
        #expect(receivedConfig?.source.sourceId == expectedConfig?.source.sourceId)
        #expect(configUpdateCount == 2) // Initial state + successful update
    }
    
    @Test("given storage has a valid cached source config, when fetchCachedConfig and the launch fetch run, then both complete successfully")
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
        
        analytics.sourceConfigState.publisher
            .sink { config in
                receivedConfigs.append(config)
            }
            .store(in: &cancellables)
        
        sourceConfigProvider.fetchCachedConfigAndNotifyObservers() // Should load from cache
        sourceConfigProvider.fetchConfigAtLaunchAndNotifyObservers() // Should attempt network fetch
        
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig)
        
        #expect(receivedConfigs.count >= 2) // Initial + cached config, possibly + network attempt
        
        if receivedConfigs.count >= 2 {
            let cachedConfig = receivedConfigs[1]
            #expect(cachedConfig.source.sourceId == mockConfig?.source.sourceId)
        }
    }
    
    @Test("given a SourceConfig request returning HTTP 500 error, when the launch fetch runs, then retries with exponential backoff until max attempts")
    func testHandleHTTP500WithRetries() async {
        MockProvider.setupMockURLSession()
        HttpNetwork.session = MockProvider.prepareMockSessionConfigSession(with: 500)
        
        let initialConfig = analytics.sourceConfigState.value
        var receivedConfig: SourceConfig?
        var configUpdateCount = 0
        var cancellables = Set<AnyCancellable>()
        
        defer {
            cancellables.removeAll()
            MockProvider.teardownMockURLSession()
        }
        
        analytics.sourceConfigState.publisher
            .sink { config in
                receivedConfig = config
                configUpdateCount += 1
            }
            .store(in: &cancellables)
                
        // When
        sourceConfigProvider.fetchConfigAtLaunchAndNotifyObservers()
        
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

// MARK: - Periodic Refresh
@Suite("SourceConfigProvider periodic refresh Tests")
class SourceConfigProviderRefreshTests {
    private static let intervalInMillis: UInt64 = 1_000
    
    private let mockStorage = MockStorage()
    private let requestCounter = RequestCounter()
    private var analytics: Analytics?
    
    deinit {
        MockURLProtocol.forwardGetRequestsToHandler = false
        MockProvider.teardownMockURLSession()
        let storage = self.mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    /** Returns a provider with a short interval, after the SDK's own launch fetch has stored its config. */
    private func makeProvider(refreshStatusCode: Int = 200, refreshResponseDelay: TimeInterval = 0) async -> (Analytics, SourceConfigProvider) {
        let counter = self.requestCounter
        MockURLProtocol.forwardGetRequestsToHandler = true
        MockURLProtocol.requestHandler = { request in
            guard request.httpMethod == "GET" else { return (200, nil, nil) }
            let isLaunchFetch = counter.increment() == 0
            if !isLaunchFetch { Thread.sleep(forTimeInterval: refreshResponseDelay) }
            let statusCode = isLaunchFetch ? 200 : refreshStatusCode
            let json = statusCode == 200 ? (MockProvider.sourceConfigurationDictionary ?? [:]) : ["error": "Server error"]
            return (statusCode, try JSONSerialization.data(withJSONObject: json), ["Content-Type": "application/json"])
        }
        let analytics = MockProvider.createMockAnalytics(storage: mockStorage)
        self.analytics = analytics
        await mockStorage.waitForKeyValue(key: Constants.storageKeys.sourceConfig)
        analytics.sourceConfigProvider?.stopPeriodicRefresh()
        analytics.lifecycleObserver?.handle(.background)
        counter.reset()
        
        let provider = SourceConfigProvider(analytics: analytics, refreshIntervalInMillis: Self.intervalInMillis)
        provider.fetchConfigAtLaunchAndNotifyObservers()
        await waitUntil { provider.lastFetchEndInMillis != nil }
        return (analytics, provider)
    }
    
    private func waitUntil(timeout: TimeInterval = 5.0, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: MockStorage.pollInterval)
        }
    }
    
    private func sleep(milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
    
    @Test("given a long foreground session, when the loop runs, then no refresh happens before the interval and one happens after it")
    func testForegroundSessionRefreshesOncePerInterval() async {
        let (analytics, provider) = await makeProvider()
        analytics.lifecycleObserver?.addObserver(provider)
        analytics.lifecycleObserver?.handle(.foreground)
        
        await sleep(milliseconds: Self.intervalInMillis / 2)
        #expect(requestCounter.count == 1)
        
        await waitUntil { self.requestCounter.count == 2 }
        #expect(requestCounter.count == 2)
        provider.stopPeriodicRefresh()
    }
    
    @Test("given the app is in the background, when it returns after the interval, then the provider fetches at once, and a quick return does not fetch")
    func testBackgroundThenReturn() async {
        let (analytics, provider) = await makeProvider()
        analytics.lifecycleObserver?.addObserver(provider)
        
        await sleep(milliseconds: Self.intervalInMillis * 3 / 2)
        #expect(requestCounter.count == 1)
        
        let launchFetchEnd = provider.lastFetchEndInMillis
        analytics.lifecycleObserver?.handle(.foreground)
        await waitUntil(timeout: Double(Self.intervalInMillis) / 2_000) { provider.lastFetchEndInMillis != launchFetchEnd }
        #expect(requestCounter.count == 2)
        
        analytics.lifecycleObserver?.handle(.background)
        analytics.lifecycleObserver?.handle(.foreground)
        await sleep(milliseconds: Self.intervalInMillis / 2)
        #expect(requestCounter.count == 2)
        provider.stopPeriodicRefresh()
    }
    
    @Test("given a refresh is in flight, when the app goes to the background, then the fetch records no end and the next foreground fetches at once")
    func testCancelledRefreshRecordsNoEnd() async {
        let (analytics, provider) = await makeProvider(refreshResponseDelay: 0.5)
        analytics.lifecycleObserver?.addObserver(provider)
        await sleep(milliseconds: Self.intervalInMillis)
        let launchFetchEnd = provider.lastFetchEndInMillis
        
        analytics.lifecycleObserver?.handle(.foreground)
        await waitUntil { self.requestCounter.count == 2 }
        analytics.lifecycleObserver?.handle(.background)
        await sleep(milliseconds: 800) // Longer than the response delay, so the cancelled fetch has ended
        #expect(provider.lastFetchEndInMillis == launchFetchEnd)
        
        analytics.lifecycleObserver?.handle(.foreground)
        await waitUntil { self.requestCounter.count == 3 }
        provider.stopPeriodicRefresh()
        #expect(requestCounter.count == 3)
    }
    
    @Test("given the launch fetch is still running, when the loop starts, then the loop waits for it and does not fetch at once")
    func testLoopWaitsForLaunchFetch() async {
        let (analytics, _) = await makeProvider()
        let counter = RequestCounter()
        MockURLProtocol.requestHandler = { request in
            guard request.httpMethod == "GET" else { return (200, nil, nil) }
            counter.increment()
            Thread.sleep(forTimeInterval: 0.5)
            return (200, try JSONSerialization.data(withJSONObject: MockProvider.sourceConfigurationDictionary ?? [:]), ["Content-Type": "application/json"])
        }
        let provider = SourceConfigProvider(analytics: analytics, refreshIntervalInMillis: Self.intervalInMillis)
        
        provider.fetchConfigAtLaunchAndNotifyObservers()
        provider.startPeriodicRefresh()
        await waitUntil { provider.lastFetchEndInMillis != nil }
        await sleep(milliseconds: Self.intervalInMillis / 2)
        provider.stopPeriodicRefresh()
        
        #expect(counter.count == 1)
    }
    
    @Test("given a refresh returns 400, when the loop runs, then the SDK keeps its config and does not shut down")
    func testRefreshWith400KeepsConfig() async {
        let (analytics, provider) = await makeProvider(refreshStatusCode: 400)
        let configBeforeRefresh = analytics.sourceConfigState.value
        
        let launchFetchEnd = provider.lastFetchEndInMillis
        provider.startPeriodicRefresh()
        await waitUntil { provider.lastFetchEndInMillis != launchFetchEnd }
        provider.stopPeriodicRefresh()
        
        #expect(requestCounter.count == 2) // One attempt, no backoff retries
        #expect(!analytics.isAnalyticsShutdown)
        #expect(analytics.sourceConfigState.value == configBeforeRefresh)
    }
    
    @Test("given an interval below one minute, when the test hook sets it, then the provider uses one minute")
    func testRefreshIntervalForTestingHasMinimum() async {
        let (_, provider) = await makeProvider()
        
        provider.setRefreshIntervalForTesting(milliseconds: 1)
        #expect(provider.refreshIntervalInMillis == SourceConfigProvider.minTestRefreshIntervalInMillis)
        
        provider.setRefreshIntervalForTesting(milliseconds: 120_000)
        #expect(provider.refreshIntervalInMillis == 120_000)
    }
    
    @Test("given a last fetch end, a current time, and an interval, when the delay is computed, then it is the time left, or zero when due",
          arguments: [
            (lastFetchEnd: UInt64?.none, now: UInt64(5_000), expected: UInt64(0)),
            (lastFetchEnd: UInt64?.some(5_000), now: UInt64(5_400), expected: UInt64(600)),
            (lastFetchEnd: UInt64?.some(5_000), now: UInt64(6_000), expected: UInt64(0)),
            (lastFetchEnd: UInt64?.some(5_000), now: UInt64(4_000), expected: UInt64(0))
          ])
    func testTimeUntilNextFetch(lastFetchEnd: UInt64?, now: UInt64, expected: UInt64) {
        let delay = SourceConfigProvider.timeUntilNextFetch(lastFetchEndInMillis: lastFetchEnd, nowInMillis: now, intervalInMillis: Self.intervalInMillis)
        #expect(delay == expected)
    }
}

/** Counts requests from the URL loading thread and the test thread. */
private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    
    var count: Int { lock.withLock { value } }
    
    @discardableResult
    func increment() -> Int {
        lock.withLock {
            defer { value += 1 }
            return value
        }
    }
    
    func reset() { lock.withLock { value = 0 } }
}
