//
//  SourceConfigProvider.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 15/09/25.
//

import Foundation
import Combine

/**
 Manages fetching, caching, and providing the source configuration data from the RudderStack server.
 */
class SourceConfigProvider: TypeIdentifiable {
    private weak var analytics: Analytics?
    private let sourceConfigState: StateImpl<SourceConfig>
    private let httpClient: HttpClient
    private var backoffPolicy: BackoffPolicy?
    
    private var connectivityMonitor: Connectivity? = Connectivity()
    private let refreshIntervalInMillis: UInt64
    
    @Synchronized private var launchFetchTask: Task<Void, Never>?
    @Synchronized private var refreshTask: Task<Void, Never>?
    @Synchronized private(set) var lastFetchEndInMillis: UInt64?
    
    private static let maxRetryAttempts = 5
    private static let defaultRefreshIntervalInMillis: UInt64 = 3_600_000 // 1 hour
    
    init(analytics: Analytics, backoffPolicy: BackoffPolicy = ExponentialBackoffPolicy(), refreshIntervalInMillis: UInt64 = SourceConfigProvider.defaultRefreshIntervalInMillis) {
        self.analytics = analytics
        self.sourceConfigState = analytics.sourceConfigState
        self.httpClient = HttpClient(analytics: analytics)
        self.backoffPolicy = backoffPolicy
        self.refreshIntervalInMillis = refreshIntervalInMillis
    }
    
    func fetchCachedConfigAndNotifyObservers() {
        guard let cachedSourceConfig = self.fetchCachedSourceConfig() else { return }
        self.notifyObservers(config: cachedSourceConfig)
    }
    
    func fetchConfigAtLaunchAndNotifyObservers() {
        let connectivityState = self.connectivityMonitor?.connectivityState
        self.launchFetchTask = Task { [weak self] in
            await Self.waitForConnection(connectivityState)
            await self?.fetchAndNotifyObservers { await $0.downloadSourceConfig() }
        }
    }
    
    private func fetchAndNotifyObservers(download: (SourceConfigProvider) async -> SourceConfig?) async {
        let downloadedSourceConfig = await download(self)
        // A cancelled refresh applies nothing and records no end, so the next foreground fetches at once.
        guard !Task.isCancelled else { return }
        
        if let downloadedSourceConfig {
            self.notifyObservers(config: downloadedSourceConfig)
        }
        self.lastFetchEndInMillis = Self.currentTimeInMillis
    }
    
    private func notifyObservers(config: SourceConfig) {
        analytics?.logger.verbose(log: "\(className): Notifying observers with sourceConfig")
        self.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: config))
    }
    
    private static func waitForConnection(_ connectivityState: AnyPublisher<Bool, Never>?) async {
        guard let connectivityState else { return }
        for await isConnected in connectivityState.values where isConnected {
            return
        }
    }
    
    private static var currentTimeInMillis: UInt64 {
        let millisecondsPerSecond: Double = 1_000
        return UInt64(Date().timeIntervalSince1970 * millisecondsPerSecond)
    }
    
    deinit {
        self.refreshTask?.cancel()
    }
}

// MARK: - Periodic Refresh
extension SourceConfigProvider: LifecycleEventListener {
    
    func onForeground() {
        self.startPeriodicRefresh()
    }
    
    func onBackground() {
        self.stopPeriodicRefresh()
    }
    
    func startPeriodicRefresh() {
        $refreshTask.modify { refreshTask in
            guard refreshTask == nil else { return }
            refreshTask = self.refreshPeriodically()
        }
    }
    
    func stopPeriodicRefresh() {
        $refreshTask.modify { refreshTask in
            refreshTask?.cancel()
            refreshTask = nil
        }
    }
    
    private func refreshPeriodically() -> Task<Void, Never> {
        let launchFetchTask = self.launchFetchTask
        let connectivityState = self.connectivityMonitor?.connectivityState
        
        // Holds no strong reference while it waits, so the provider can deinit and cancel the loop.
        return Task { [weak self] in
            await launchFetchTask?.value
            while !Task.isCancelled {
                guard let delayInMillis = self?.timeUntilNextRefresh() else { return }
                do {
                    try await BackoffPolicyHelper.sleep(milliseconds: Int(delayInMillis))
                } catch {
                    return
                }
                await Self.waitForConnection(connectivityState)
                guard !Task.isCancelled else { return }
                await self?.fetchAndNotifyObservers { await $0.downloadSourceConfigOnce() }
            }
        }
    }
    
    private func timeUntilNextRefresh() -> UInt64 {
        return Self.timeUntilNextFetch(lastFetchEndInMillis: self.lastFetchEndInMillis, nowInMillis: Self.currentTimeInMillis, intervalInMillis: self.refreshIntervalInMillis)
    }
    
    /** A clock that moved back counts as due. */
    static func timeUntilNextFetch(lastFetchEndInMillis: UInt64?, nowInMillis: UInt64, intervalInMillis: UInt64) -> UInt64 {
        guard let lastFetchEndInMillis, nowInMillis >= lastFetchEndInMillis else { return 0 }
        let elapsedInMillis = nowInMillis - lastFetchEndInMillis
        return elapsedInMillis >= intervalInMillis ? 0 : intervalInMillis - elapsedInMillis
    }
}

// MARK: - Cached SourceConfig
extension SourceConfigProvider {
    
    private func fetchCachedSourceConfig() -> SourceConfig? {
        guard let storedSourceConfig = self.analytics?.storage.read(key: Constants.storageKeys.sourceConfig) as String?,
              let sourceConfigData = storedSourceConfig.utf8Data else {
            analytics?.logger.debug(log: "\(className): SourceConfig not found in storage")
            return nil
        }
        
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: sourceConfigData)
            analytics?.logger.debug(log: "\(className): SourceConfig fetched from storage: \(sourceConfig)")
            
            return sourceConfig
        } catch {
            analytics?.logger.error(log: "Failed to decode SourceConfig from storage: \(error)", error: error)
            return nil
        }
    }
}

// MARK: - Downloaded SourceConfig
extension SourceConfigProvider {
    private func downloadSourceConfig() async -> SourceConfig? {
        var attemptCount = 0
        
        repeat {
            attemptCount += 1
            let configResult = await self.httpClient.getConfigurationData()
            
            switch configResult {
            case .success(let data):
                return self.handleSourceConfigResponse(data: data)
                
            case .failure(let error):
                guard await self.handleSourceConfigError(error, attemptCount: attemptCount) else { return nil }
            }
        } while attemptCount <= Self.maxRetryAttempts
        
        return nil
    }
    
    private func downloadSourceConfigOnce() async -> SourceConfig? {
        switch await self.httpClient.getConfigurationData() {
        case .success(let data):
            return self.handleSourceConfigResponse(data: data)
            
        case .failure(let error):
            // A refresh never shuts down the SDK: uploads and the next launch already handle an invalid write key.
            analytics?.logger.error(log: "\(className): Error refreshing SourceConfig: \(error.errorDescription). Keeping the current config", error: error)
            return nil
        }
    }
    
    private func handleSourceConfigResponse(data: Data) -> SourceConfig? {
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: data)
            analytics?.logger.debug(log: "\(className): SourceConfig downloaded: \(sourceConfig)")
            
            self.analytics?.storage.write(value: sourceConfig.jsonString, key: Constants.storageKeys.sourceConfig)
            return sourceConfig
        } catch {
            analytics?.logger.error(log: "Failed to decode SourceConfig from response: \(error)", error: error)
            return nil
        }
    }
    
    private func handleSourceConfigError(_ error: SourceConfigError, attemptCount: Int) async -> Bool {
        analytics?.logger.error(log: "\(className): Error downloading SourceConfig: \(error.errorDescription)", error: error)

        switch error {
        case .invalidWriteKey:
            self.analytics?.handleInvalidWriteKey()
            return false
            
        default:
            guard let backoffPolicy, attemptCount <= Self.maxRetryAttempts else {
                analytics?.logger.warn(log: "\(className): All retry attempts for fetching SourceConfig have been exhausted. Returning nil")
                return false
            }
    
            let delay = backoffPolicy.nextDelayInMilliseconds()
            analytics?.logger.verbose(log: "\(className): Retrying fetching of SourceConfig, attempt: \(attemptCount) in \(BackoffPolicyHelper.formatMilliseconds(delay))")
            try? await BackoffPolicyHelper.sleep(milliseconds: delay)
            return true
        }
    }
}
