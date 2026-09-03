//
//  IntegrationPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation

/**
 StandardIntegration is a protocol that represents a standard integration plugin. All the integrations maintained by RudderStack will conform to this protocol.
 **Caution:** This protocol is considered internal and may change without notice. It is intended solely for use within RudderStack-maintained repositories and should not be referenced by external clients.
 */
public protocol StandardIntegration: AnyObject {}

/**
 * Base protocol for all integration plugins.
 *
 * An integration plugin is a plugin that is responsible for sending events directly
 * to a 3rd party destination without sending it to Rudder server first.
 */
public protocol IntegrationPlugin: EventPlugin, AnyObject {
    
    /**
     The key for the destination present in the source config.
     */
    var key: String { get set }
    
    /**
     Returns the instance of the destination which was created.

     - Returns: The instance of the destination, or nil if not created.
     */
    func getDestinationInstance() -> Any?
    
    /**
     Creates the destination instance. Override this method for the initialization of destination.

     - Parameter destinationConfig: The configuration for the destination as a dictionary.
     - Throws: Any error that occurs during destination creation.
     */
    func create(destinationConfig: [String: Any]) throws
    
    /**
     This method will be called when the destination configuration is updated.
     The value could be either destination config or empty dictionary.

     - Parameter destinationConfig: The updated configuration for the destination.
     - Throws: Any error that occurs during destination updation.
     */
    func update(destinationConfig: [String: Any]) throws
    
    /**
     Override this method to control the behaviour of flush for this destination.
     */
    func flush()
    
    /**
     Override this method to control the behaviour of reset for this destination.
     */
    func reset()
}

public extension IntegrationPlugin {
    
    /**
     Default implementation for update.
     */
    func update(destinationConfig: [String: Any]) throws {
        /* Default implementation (no-op) */
    }
    
    /**
     Default implementation for flush.
     */
    func flush() {
        /* Default implementation (no-op) */
    }
    
    /**
     Default implementation for reset.
     */
    func reset() {
        /* Default implementation (no-op) */
    }
}

public extension IntegrationPlugin {
  
    /**
    This method adds a plugin to modify the events before sending to this destination.
     
    - Parameter plugin The plugin to be added.
    */
    func add(plugin: Plugin) {
        self.pluginChain?.add(plugin: plugin)
    }
    
    /**
     This method removes a plugin from the destination.
     
     - Parameter plugin The plugin to be removed.
     */
    func remove(plugin: Plugin) {
        self.pluginChain?.remove(plugin: plugin)
    }
    
    /**
    Registers a callback to be invoked when the destination of this plugin is ready.

    - Parameter callback: The callback to be invoked when the destination is ready.
    */
    func onDestinationReady(callback: @escaping IntegrationCallback) {
        guard let pluginStore else { return }
        
        if let destinationInstance = getDestinationInstance() {
            if pluginStore.isDestinationReady {
                callback(destinationInstance, .success(()))
            } else {
                callback(nil, .failure(DestinationError.destinationNotReady(key)))
            }
        } else {
            // Store callback for later notification when destination becomes ready
            pluginStore.destinationReadyCallbacks.append(callback)
        }
    }
}

public extension IntegrationPlugin {
    
    /**
     Default implementation of `intercept` method for `IntegrationPlugin`.
     
     **Caution:** This method is a default implementation provided by the SDK.
     Clients should not override, reimplement or call this method externally, as it will lead to
     unexpected behavior or break internal logic.
     */
    func intercept(event: any Event) -> (any Event)? {
        guard let pluginStore else { return event }
        if pluginStore.isDestinationReady {
            // Apply plugin chain processing
                        
            let preProcessedEvent = pluginChain?.applyPlugins(pluginType: .preProcess, event: event)
            let onProcessedEvent = pluginChain?.applyPlugins(pluginType: .onProcess, event: preProcessedEvent)
            
            // Handle the event after plugin processing
            if let finalEvent = onProcessedEvent {
                self.handleEvent(event: self.consentRestampedEvent(finalEvent))
            }
        } else {
            // Hold events that arrive while this destination's `create()` is in flight — the init
            // window opens on every creation attempt, not only consent-driven re-inits; no-op
            // when no window is open (existing skip behavior applies).
            analytics?.integrationsController?.bufferIfReinitializing(event: event, key: key)
        }
        return event
    }
    
    /**
     Default implementation of `setup` method for `IntegrationPlugin`.
     
     **Caution:** This method is a default implementation provided by the SDK.
     Clients should not override, reimplement or call this method externally, as it will lead to
     unexpected behavior or break internal logic.
     */
    func setup(analytics: Analytics) {
        self.analytics = analytics
        
        let key = self.key
        analytics.integrationsController?.$integrationPluginStores.modify { stores in
            if stores[key] == nil {
                let pluginStore = IntegrationPluginStore(analytics: analytics)
                
                pluginStore.isStandardIntegration = self is StandardIntegration
                stores[key] = pluginStore
            }
        }
        
        self.applyDefaultPlugins()
    }
}

extension IntegrationPlugin {
    var pluginStore: IntegrationPluginStore? {
        return self.analytics?.integrationsController?.integrationPluginStores[self.key]
    }
    
    var pluginChain: PluginChain? {
        return self.pluginStore?.pluginChain
    }
    
    private func applyDefaultPlugins() {
        self.add(plugin: ConsentGatePlugin(key: self.key))
        self.add(plugin: EventFilteringPlugin(key: self.key))
        self.add(plugin: IntegrationOptionsPlugin(key: self.key))
    }
    
    /**
     Re-asserts `context.consentManagement` from the current consent state before the event is
     handed to the destination — the destination's own plugin chain runs after the main-chain
     guard, so a value written there would otherwise survive. Drift is corrected silently: the
     fan-out drains asynchronously, so a state change since the terminal stamp is expected,
     not a customer override.
     */
    private func consentRestampedEvent(_ event: any Event) -> any Event {
        guard let state = analytics?.consentManagementState.value, state.enabled else { return event }
        
        let stampKey = SDKManagedContextKey.consentManagement.rawValue
        guard event.context?[stampKey] != AnyCodable(state.contextStamp) else { return event }
        
        analytics?.logger.debug(log: "IntegrationPlugin: Refreshed the consent stamp before delivery to destination \(key).")
        return event.addToContext(info: [stampKey: state.contextStamp])
    }
}

/**
 Alias for representing a callback to report integration ready status.
 */
public typealias IntegrationCallback = (Any?, DestinationResult) -> Void

/**
 Represents the result of a destination initialization operation.
 */
public typealias DestinationResult = Result<Void, Error>
