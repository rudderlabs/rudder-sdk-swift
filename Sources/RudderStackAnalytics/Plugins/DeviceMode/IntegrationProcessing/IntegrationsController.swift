//
//  IntegrationsController.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 15/10/25.
//

import Foundation

/**
 This class is responsible for initializing or updating integrations based on the source configuration. It also manages the lifecycle of integrations by maintaining their references and invoking the appropriate `add`, `remove`, `reset`, and `flush` APIs as required.
 */
class IntegrationsController {
    
    var integrationPluginChain: PluginChain?
    var analytics: Analytics?
    
    @Synchronized var isSourceEnabledFetchedAtLeastOnce = false
    @Synchronized var integrationPluginStores: [String: IntegrationPluginStore] = [:]
    
    private let deliveryControl = DestinationDeliveryControl()
    
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
    
    // Delivers an event to a destination, holds it while that destination is initializing, or
    // skips it when the destination is neither.
    func deliver(event: Event, to integration: IntegrationPlugin) {
        deliveryControl.admit(event, for: integration.key) { admitted in
            integration.process(event: admitted)
        }
    }
    
    // Begins holding for every destination that is not yet delivering, ahead of initializing any of
    // them. Destinations are initialized one at a time, so a hold opened inside that loop would only
    // begin once the destinations ahead of it had finished creating — losing everything sent in the
    // meantime. Destinations already delivering are left alone: they have nothing to hold, and
    // putting one on hold here would leave it holding forever whenever initialization is a no-op.
    func beginBufferingForPendingDestinations() {
        self.integrationPluginChain?.apply { plugin in
            guard let integration = plugin as? IntegrationPlugin,
                  integration.pluginStore?.isDestinationReady == false else { return }
            self.deliveryControl.beginBuffering(for: integration.key)
        }
    }
    
    func add(integration: IntegrationPlugin) {
        self.integrationPluginChain?.add(plugin: integration)
        
        // If the source config is already fetched once and enabled, then initialise the destination
        // since it is added after fetching of source config.
        if isSourceEnabledFetchedAtLeastOnce, let sourceConfig = self.analytics?.sourceConfigState.value {
            self.initDestination(sourceConfig: sourceConfig, integration: integration)
        }
    }
    
    func remove(integration: IntegrationPlugin) {
        let key = integration.key
        $integrationPluginStores.modify { stores in
            stores.removeValue(forKey: key)
        }
        self.deliveryControl.markNotReady(for: key)
        self.integrationPluginChain?.remove(plugin: integration)
    }
    
    func reset() {
        self.integrationPluginChain?.apply { plugin in
            if let integrationPlugin = plugin as? IntegrationPlugin {
                if integrationPlugin.pluginStore?.isDestinationReady == true {
                    integrationPlugin.reset()
                } else {
                    analytics?.logger.debug(log: "IntegrationsController: Destination \(integrationPlugin.key) is not ready. Reset discarded.")
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
                    analytics?.logger.debug(log: "IntegrationsController: Destination \(integrationPlugin.key) is not ready. Flush discarded.")
                }
            }
        }
    }
    
    deinit {
        $integrationPluginStores.modify { stores in
            stores.removeAll()
        }
        self.deliveryControl.removeAll()
        self.integrationPluginChain?.removeAll()
        self.analytics = nil
        self.integrationPluginChain = nil
    }
}

private extension IntegrationsController {
    
    func isDestinationConfigured(sourceConfig: SourceConfig, integration: IntegrationPlugin) -> [String: Any]? {
        guard let pluginStore = integration.pluginStore else { return nil }
        
        if !pluginStore.isStandardIntegration {
            return [:]
        }
        
        guard let destination = findDestination(sourceConfig: sourceConfig, key: integration.key) else {
            let error = DestinationError.destinationNotFound(integration.key)
            analytics?.logger.warn(log: "IntegrationsController: \(error.errorDescription)")
            notifyFailureAndMarkNotReady(
                error: error,
                integration: integration
            )
            return nil
        }
        
        if !destination.isDestinationEnabled {
            let error = DestinationError.destinationDisabled(integration.key)
            analytics?.logger.warn(log: "IntegrationsController: \(error.errorDescription)")
            notifyFailureAndMarkNotReady(
                error: error,
                integration: integration
            )
            return nil
        }
        
        let destinationConfig = destination.destinationConfig.rawDictionary
        
        if let consentState = analytics?.consentManagementState.value, !ConsentResolver.resolve(state: consentState, destinationConfig: destinationConfig) {
            let error = DestinationError.destinationConsentDenied(integration.key)
            analytics?.logger.warn(log: "IntegrationsController: \(error.errorDescription)")
            
            notifyFailureAndMarkNotReady(
                error: error,
                integration: integration
            )
            return nil
        }
        
        return destinationConfig
    }
    
    func safelyInitOrUpdateAndNotify(destinationConfig: [String: Any], integration: IntegrationPlugin) {
        if integration.getDestinationInstance() == nil {
            safelyCreateAndNotify(destinationConfig: destinationConfig, integration: integration)
        } else {
            safelyUpdateAndNotify(destinationConfig: destinationConfig, integration: integration)
        }
    }
    
    func safelyCreateAndNotify(destinationConfig: [String: Any], integration: IntegrationPlugin) {
        deliveryControl.beginBuffering(for: integration.key)
        do {
            try integration.create(destinationConfig: destinationConfig)
            analytics?.logger.debug(log: "IntegrationsController: Destination \(integration.key) created successfully.")
            integration.pluginStore?.isDestinationReady = true
            markReadyAndReplay(for: integration)
            notifyCallbacks(.success(()), for: integration)
        } catch {
            analytics?.logger.error(log: "IntegrationsController: Error: \(error.localizedDescription) creating destination \(integration.key).", error: error)
            integration.pluginStore?.isDestinationReady = false
            notifyCallbacks(.failure(error), for: integration)
            discardBufferedEvents(for: integration)
        }
    }
    
    // A destination we are declaring failed must not be updated: pushing an empty config can throw,
    // which would replace the real reason with a parse error, and can reset a live destination's state.
    func notifyFailureAndMarkNotReady(error: Error, integration: IntegrationPlugin) {
        integration.pluginStore?.isDestinationReady = false
        deliveryControl.markNotReady(for: integration.key)
        notifyCallbacks(.failure(error), for: integration)
    }
    
    func safelyUpdateAndNotify(destinationConfig: [String: Any], integration: IntegrationPlugin) {
        safelyUpdateAndApplyBlock(
            destinationConfig: destinationConfig,
            integration: integration,
            block: {
                self.analytics?.logger.debug(log: "IntegrationsController: Destination \(integration.key) updated with destinationConfig: \(destinationConfig).")
                integration.pluginStore?.isDestinationReady = true
                self.markReadyAndReplay(for: integration)
                self.notifyCallbacks(.success(()), for: integration)
            }
        )
    }
    
    func safelyUpdateAndApplyBlock(destinationConfig: [String: Any], integration: IntegrationPlugin, block: @escaping () -> Void) {
        guard let pluginStore = integration.pluginStore else { return }
        
        do {
            // updating is only done for standard integrations as they depend on SourceConfig
            if pluginStore.isStandardIntegration {
                try integration.update(destinationConfig: destinationConfig)
                block()
            }
        } catch {
            analytics?.logger.error(log: "IntegrationsController: Error: \(error.localizedDescription) updating destination \(integration.key).", error: error)
            integration.pluginStore?.isDestinationReady = false
            deliveryControl.markNotReady(for: integration.key)
            notifyCallbacks(.failure(error), for: integration)
        }
    }
    
    func notifyCallbacks(_ result: DestinationResult, for integration: IntegrationPlugin) {
        guard let pluginStore = integration.pluginStore else { return }
        let instance = integration.getDestinationInstance()
        var toRun: [IntegrationCallback] = []
        // Atomically read and clear callbacks
        pluginStore.$destinationReadyCallbacks.modify { callbacks in
            toRun = callbacks
            callbacks.removeAll()
        }
        toRun.forEach { $0(instance, result) }
    }
    
    func findDestination(sourceConfig: SourceConfig, key: String) -> Destination? {
        return sourceConfig.source.destinations.first { $0.destinationDefinition.displayName == key }
    }
}

private extension IntegrationsController {
    private func markReadyAndReplay(for integration: IntegrationPlugin) {
        deliveryControl.markReady(for: integration.key) { events in
            guard !events.isEmpty else { return }
            
            analytics?.logger.debug(log: "IntegrationsController: Replaying \(events.count) buffered event(s) for destination \(integration.key).")
            // Handed straight to the destination rather than re-admitted: admitting would put these
            // events back into the hold they are being released from.
            events.forEach { integration.process(event: $0) }
        }
    }
    
    private func discardBufferedEvents(for integration: IntegrationPlugin) {
        let discarded = deliveryControl.markNotReady(for: integration.key)
        guard discarded > 0 else { return }
        
        analytics?.logger.warn(log: "IntegrationsController: Discarded \(discarded) buffered event(s) for destination \(integration.key) after failed initialization.")
    }
}
