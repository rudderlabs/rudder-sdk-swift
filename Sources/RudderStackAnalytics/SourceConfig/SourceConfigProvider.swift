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
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.sourceConfigState = analytics.sourceConfigState
    }
    
    func fetchCachedConfigAndNotifyObservers() {
        guard let cachedSourceConfig = self.fetchCachedSourceConfig() else { return }
        self.notifyObservers(config: cachedSourceConfig)
    }
}

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
    
    private func notifyObservers(config: SourceConfig) {
        LoggerAnalytics.debug(log: "Notifying observers with sourceConfig.")
    }
}
