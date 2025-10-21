//
//  IntegrationsController.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 15/10/25.
//

import Foundation

class IntegrationsController {
    
    var integrationPluginChain: PluginChain?
    var analytics: Analytics?
    @Synchronized
    var isSourceEnabledFetchedAtLeastOnce = false
    
    @Synchronized
    var integrationPluginStores: [String: IntegrationPluginStore] = [:]
    
    // TODO: - Create list of defaultPlugins
    var defaultPlugins: [Plugin] = []
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.integrationPluginChain = PluginChain(analytics: analytics)
    }
    
    func initDestination(sourceConfig: SourceConfig, integration: IntegrationPlugin) {
        guard let destinationConfig = isDestinationConfigured(sourceConfig: sourceConfig, integration: integration) else {
            return
        }
        
        safelyInitOrUpdateAndNotify(destinationConfig: destinationConfig, integration: integration)
    }
    
    private func isDestinationConfigured(sourceConfig: SourceConfig, integration: IntegrationPlugin) -> [String: Any]? {
        guard let pluginStore = integration.pluginStore else { return nil }
        
        if !pluginStore.isStandardIntegration {
            return [:]
        }
        
        guard let destination = findDestination(sourceConfig: sourceConfig, key: integration.key) else {
            let errorMessage = "Destination \(integration.key) not found in the source config. No events will be sent to this destination."
            LoggerAnalytics.warn("IntegrationsController: \(errorMessage)")
            safelyUpdateOnFailureAndNotify(
                throwable: NSError(domain: "IntegrationsController", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]),
                integration: integration
            )
            return nil
        }
        
        if !destination.isDestinationEnabled {
            let errorMessage = "Destination \(integration.key) is disabled in dashboard. No events will be sent to this destination."
            LoggerAnalytics.warn("IntegrationsController: \(errorMessage)")
            safelyUpdateOnFailureAndNotify(
                throwable: NSError(domain: "IntegrationsController", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]),
                integration: integration
            )
            return nil
        }
        
        return destination.destinationConfig.rawDictionary
    }
    
    private func safelyInitOrUpdateAndNotify(destinationConfig: [String: Any], integration: IntegrationPlugin) {
        if integration.getDestinationInstance() == nil {
            safelyCreateAndNotify(destinationConfig: destinationConfig, integration: integration)
        } else {
            safelyUpdateAndNotify(destinationConfig: destinationConfig, integration: integration)
        }
    }
    
    private func safelyCreateAndNotify(destinationConfig: [String: Any], integration: IntegrationPlugin) {
        do {
            try integration.create(destinationConfig: destinationConfig)
            LoggerAnalytics.debug("IntegrationsController: Destination \(integration.key) created successfully.")
            integration.pluginStore?.isDestinationReady = true
            notifyCallbacks(.success, for: integration)
        } catch {
            LoggerAnalytics.error("IntegrationsController: Error: \(error.localizedDescription) creating destination \(integration.key).")
            integration.pluginStore?.isDestinationReady = false
            notifyCallbacks(.failure(error), for: integration)
        }
    }
    
    private func safelyUpdateOnFailureAndNotify(throwable: Error, integration: IntegrationPlugin) {
        safelyUpdateAndApplyBlock(
            destinationConfig: [:],
            integration: integration,
            block: {
                LoggerAnalytics.debug("IntegrationsController: Destination \(integration.key) updated with empty destinationConfig.")
                integration.pluginStore?.isDestinationReady = false
                self.notifyCallbacks(.failure(throwable), for: integration)
            }
        )
    }
    
    private func safelyUpdateAndNotify(destinationConfig: [String: Any], integration: IntegrationPlugin) {
        safelyUpdateAndApplyBlock(
            destinationConfig: destinationConfig,
            integration: integration,
            block: {
                LoggerAnalytics.debug("IntegrationsController: Destination \(integration.key) updated with destinationConfig: \(destinationConfig).")
                integration.pluginStore?.isDestinationReady = true
                self.notifyCallbacks(.success, for: integration)
            }
        )
    }
    
    private func safelyUpdateAndApplyBlock(destinationConfig: [String: Any], integration: IntegrationPlugin, block: @escaping () -> Void) {
        guard let pluginStore = integration.pluginStore else { return }
        
        do {
            // updating is only done for standard integrations as they depend on SourceConfig
            if pluginStore.isStandardIntegration {
                try integration.update(destinationConfig: destinationConfig)
                block()
            }
        } catch {
            LoggerAnalytics.error("IntegrationsController: Error: \(error.localizedDescription) updating destination \(integration.key).")
            integration.pluginStore?.isDestinationReady = false
            notifyCallbacks(.failure(error), for: integration)
        }
    }
    
    func notifyCallbacks(_ result: DestinationResult, for integration: IntegrationPlugin) {
        guard let pluginStore = integration.pluginStore else { return }
        // Atomically read and clear callbacks
        pluginStore.$destinationReadyCallbacks.modify { callbacks in
            let instance = integration.getDestinationInstance()
            callbacks.forEach { $0(instance, result) }
            callbacks.removeAll()
        }
    }
    
    func add(integration: IntegrationPlugin) {
        self.integrationPluginChain?.add(plugin: integration)
        self.defaultPlugins.forEach { integration.add(plugin: $0) }
        
        let key = integration.key
        $integrationPluginStores.modify { stores in
            if stores[key] == nil, let analytics {
                let pluginStore = IntegrationPluginStore(analytics: analytics)
                
                pluginStore.isStandardIntegration = integration is StandardIntegration
                stores[key] = pluginStore
            }
        }
        
        // If the source config is already fetched once and enabled, then initialise the destination
        // since it is added after fetching of source config.
        if isSourceEnabledFetchedAtLeastOnce, let sourceConfig = self.analytics?.sourceConfigState.state.value {
            self.initDestination(sourceConfig: sourceConfig, integration: integration)
        }
    }
    
    func remove(integration: IntegrationPlugin) {
        let key = integration.key
        $integrationPluginStores.modify { stores in
            stores.removeValue(forKey: key)
        }
        self.integrationPluginChain?.remove(plugin: integration)
    }
    
    func reset() {
        self.integrationPluginChain?.apply { plugin in
            if let integrationPlugin = plugin as? IntegrationPlugin {
                if integrationPlugin.pluginStore?.isDestinationReady == true {
                    integrationPlugin.reset()
                } else {
                    LoggerAnalytics.debug("IntegrationsManagementPlugin: Destination \(integrationPlugin.key) is not ready. Reset discarded.")
                }
            }
        }
    }
    
    func flush() {
        self.integrationPluginChain?.apply { plugin in
            if let integrationPlugin = plugin as? IntegrationPlugin {
                if integrationPlugin.pluginStore?.isDestinationReady == true {
                    integrationPlugin.flush()
                } else {
                    LoggerAnalytics.debug("IntegrationsManagementPlugin: Destination \(integrationPlugin.key) is not ready. Flush discarded.")
                }
            }
        }
    }
    
    private func findDestination(sourceConfig: SourceConfig, key: String) -> Destination? {
        return sourceConfig.source.destinations.first { $0.destinationDefinition.displayName == key }
    }
    
    deinit {
        $integrationPluginStores.modify { stores in
            stores.removeAll()
        }
        self.integrationPluginChain?.removeAll()
        self.defaultPlugins.removeAll()
        self.analytics = nil
        self.integrationPluginChain = nil
    }
}
