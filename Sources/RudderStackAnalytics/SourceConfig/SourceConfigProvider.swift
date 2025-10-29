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
    private var cancellables = Set<AnyCancellable>()
    
    private static let maxRetryAttempts = 5
    
    init(analytics: Analytics, backoffPolicy: BackoffPolicy = ExponentialBackoffPolicy()) {
        self.analytics = analytics
        self.sourceConfigState = analytics.sourceConfigState
        self.httpClient = HttpClient(analytics: analytics)
        self.backoffPolicy = backoffPolicy
    }
    
    func fetchCachedConfigAndNotifyObservers() {
        guard let cachedSourceConfig = self.fetchCachedSourceConfig() else { return }
        self.notifyObservers(config: cachedSourceConfig)
    }
    
    func refreshConfigAndNotifyObservers() {
        // Attempt to download the latest SourceConfig
        self.connectivityMonitor?.connectivityState
            .filter { $0 } // Proceed only when connected
            .first() // Take only the first true value
            .sink { _ in
                Task { [weak self] in
                    guard let self, let downloadedSourceConfig = await self.downloadSourceConfig() else { return }
                    self.notifyObservers(config: downloadedSourceConfig)
                }
            }
            .store(in: &cancellables)
    }
    
    private func notifyObservers(config: SourceConfig) {
        LoggerAnalytics.debug("Notifying observers with sourceConfig.")
        self.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: config))
    }
    
    deinit {
        self.cancellables.removeAll()
    }
}

// MARK: - Cached SourceConfig
extension SourceConfigProvider {
    
    private func fetchCachedSourceConfig() -> SourceConfig? {
        guard let storedSourceConfig = self.analytics?.storage.read(key: Constants.storageKeys.sourceConfig) as String?,
              let sourceConfigData = storedSourceConfig.utf8Data else {
            LoggerAnalytics.info("SourceConfig not found in storage")
            return nil
        }
        
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: sourceConfigData)
            LoggerAnalytics.info("SourceConfig fetched from storage: \(sourceConfig)")
            
            return sourceConfig
        } catch {
            LoggerAnalytics.error("Failed to decode SourceConfig from storage: \(error)")
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
    
    private func handleSourceConfigResponse(data: Data) -> SourceConfig? {
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: data)
            LoggerAnalytics.info("SourceConfig downloaded: \(sourceConfig)")
            
            self.analytics?.storage.write(value: sourceConfig.jsonString, key: Constants.storageKeys.sourceConfig)
            return sourceConfig
        } catch {
            LoggerAnalytics.error("Failed to decode SourceConfig from response: \(error)")
            return nil
        }
    }
    
    private func handleSourceConfigError(_ error: SourceConfigError, attemptCount: Int) async -> Bool {
        LoggerAnalytics.error("\(className): Error downloading SourceConfig: \(error.errorDescription)", cause: error)

        switch error {
        case .invalidWriteKey:
            self.analytics?.handleInvalidWriteKey()
            return false
            
        default:
            guard let backoffPolicy, attemptCount <= Self.maxRetryAttempts else {
                LoggerAnalytics.info("All retry attempts for fetching SourceConfig have been exhausted. Returning nil.")
                return false
            }
    
            let delay = backoffPolicy.nextDelayInMilliseconds()
            LoggerAnalytics.verbose("Retrying fetching of SourceConfig, attempt: \(attemptCount) in \(BackoffPolicyHelper.formatMilliseconds(delay))")
            try? await BackoffPolicyHelper.sleep(milliseconds: delay)
            return true
        }
    }
}
