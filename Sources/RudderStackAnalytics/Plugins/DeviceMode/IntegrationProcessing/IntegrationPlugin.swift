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
        guard pluginStore != nil else { return event }
        // Readiness and any hold on this destination are one decision, taken together, so an event
        // arriving as the destination becomes ready cannot overtake the events held before it.
        analytics?.integrationsController?.deliver(event: event, to: self)
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
    /// Runs this destination's own plugin chain and hands the event over. Called for live and for
    /// previously held events alike, so both take exactly the same path.
    func process(event: Event) {
        let preProcessedEvent = pluginChain?.applyPlugins(pluginType: .preProcess, event: event)
        let onProcessedEvent = pluginChain?.applyPlugins(pluginType: .onProcess, event: preProcessedEvent)
        
        if let finalEvent = onProcessedEvent, let deliverableEvent = self.gateAndRestoreConsentStamp(finalEvent) {
            self.handleEvent(event: deliverableEvent)
        }
    }
    
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
     Applies the live consent decision at the handoff boundary, then restores
     `context.consentManagement` to the value the event was created under.
     
     The destination's own plugins run after `ConsentGatePlugin`, so consent can be revoked after the
     gate has already passed the event. Gating here too makes that guarantee hold all the way to
     delivery rather than only at chain entry. The gate reads live state, because a revocation must
     stop delivery now; the stamp is restored from the value captured at creation.
     */
    private func gateAndRestoreConsentStamp(_ event: any Event) -> (any Event)? {
        guard let state = analytics?.consentManagementState.value, state.active else { return event }
        
        guard ConsentResolver.resolve(state: state, destinationConfig: pluginStore?.destinationConfig) else {
            analytics?.logger.debug(log: "IntegrationPlugin: Dropped event for destination: \(key) — consent was revoked while the event was in the destination chain.")
            return nil
        }
        return self.consentRestampedEvent(event)
    }
    
    /**
     Re-asserts `context.consentManagement` from the value captured when the event was created,
     before it is handed to the destination — the destination's own plugin chain runs after the
     main-chain guard, so a value written there would otherwise survive.
     
     The value restored is the one captured at creation, not the state at this instant, so a
     consent decision taken while the event was in flight cannot rewrite what the event recorded.
     Any difference at this point is therefore a destination plugin overwriting the key, which is
     warned about once per destination rather than once per event.
     */
    private func consentRestampedEvent(_ event: any Event) -> any Event {
        let stampKey = SDKManagedContextKey.consentManagement.rawValue
        guard let captured = (event as? ReservedContextCapturing)?.capturedReservedContext?[stampKey] else { return event }
        guard event.context?[stampKey] != AnyCodable(captured) else { return event }

        if pluginStore?.claimRestoreWarning() == true {
            analytics?.logger.warn(log: "IntegrationPlugin: Replacing the \"\(stampKey)\" key rewritten in the destination chain for \(key); the SDK owns this key while consent management is enabled.")
        }
        return event.addToContext(info: [stampKey: captured])
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
