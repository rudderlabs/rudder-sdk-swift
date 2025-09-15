//
//  SourceConfigProvider.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 15/09/25.
//

import Foundation

final class SourceConfigProvider {
    private weak var analytics: Analytics?
    private let sourceConfigState: StateImpl<SourceConfig>
    private let httpClient: HttpClient
    private static let maxRetryAttempts = 5
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.sourceConfigState = analytics.sourceConfigState
        self.httpClient = HttpClient(analytics: analytics)
    }
    
    func fetchCachedConfigAndNotifyObservers() {
        guard let cachedSourceConfig = self.fetchCachedSourceConfig() else { return }
        self.notifyObservers(config: cachedSourceConfig)
    }
    
    func refreshConfigAndNotifyObservers() {
        Task { [weak self] in
            guard let self, let downloadedSourceConfig = await self.downloadSourceConfig() else { return }
            self.notifyObservers(config: downloadedSourceConfig)
        }
    }
    
    private func notifyObservers(config: SourceConfig) {
        LoggerAnalytics.debug(log: "Notifying observers with sourceConfig.")
    }
}

// MARK: - Cached SourceConfig
extension SourceConfigProvider {
    
    private func fetchCachedSourceConfig() -> SourceConfig? {
        guard let storedSourceConfig = self.analytics?.storage.read(key: Constants.storageKeys.sourceConfig) as String?,
              let sourceConfigData = storedSourceConfig.utf8Data else {
            LoggerAnalytics.info(log: "SourceConfig not found in storage")
            return nil
        }
        
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: sourceConfigData)
            LoggerAnalytics.info(log: "SourceConfig fetched from storage: \(sourceConfig)")
            
            return sourceConfig
        } catch {
            LoggerAnalytics.error(log: "Failed to decode SourceConfig from storage: \(error)")
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
                LoggerAnalytics.error(log: "Error downloading SourceConfig: \(error.errorDescription)", error: error)
                // TODO: - When working on SourceConfig failure ticket, handle this scenario here.
                // https://linear.app/rudderstack/issue/SDK-3144/parent-source-config-on-unsuccessful-response
            }
        } while attemptCount <= Self.maxRetryAttempts
        
        return nil
    }
    
    private func handleSourceConfigResponse(data: Data) -> SourceConfig? {
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: data)
            LoggerAnalytics.info(log: "SourceConfig downloaded: \(sourceConfig)")
            
            self.analytics?.storage.write(value: sourceConfig.jsonString, key: Constants.storageKeys.sourceConfig)
            return sourceConfig
        } catch {
            LoggerAnalytics.error(log: "Failed to decode SourceConfig from response: \(error)")
            return nil
        }
    }
}
