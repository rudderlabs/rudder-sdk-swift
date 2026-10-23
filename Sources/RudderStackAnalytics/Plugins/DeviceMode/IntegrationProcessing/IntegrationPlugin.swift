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
     Returns the instance of the destination.

     - Returns: The instance of the destination, or nil if the integration holds none.
     */
    func getDestinationInstance() -> Any?
    
    /**
     Creates the destination. The SDK calls this method with the first valid configuration. It calls this method
     again with a later valid configuration while `getDestinationInstance()` returns `nil`.

     Initialise the destination SDK here, unless the integration already holds an instance that the app passed.
     Throw an error when the destination cannot be created. The SDK then calls this method again with the next
     valid configuration.

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
    Registers a callback that gets the result of the destination setup. The SDK calls each callback at most once.

    Until the destination is set up, the SDK stores the callback and calls it with the next result. After the setup,
    the SDK calls the callback at once with the last result. Success passes the destination instance. Failure passes
    `nil`. A standard destination that is ready with no instance keeps the callback until the next result.

    - Parameter callback: The callback that gets the destination instance and the result.
    */
    func onDestinationReady(callback: @escaping IntegrationCallback) {
        guard let pluginStore else { return }
        
        var lastResult: DestinationResult?
        pluginStore.$destinationReadyCallbacks.modify { callbacks in
            // The captured store, not a new lookup: a re-add on another thread can replace the store.
            lastResult = pluginStore.keepsLateCallbacks ? nil : pluginStore.lastResult
            if lastResult == nil {
                callbacks.append(callback)
            }
        }
        guard let lastResult else { return }
        
        switch lastResult {
        case .success:
            callback(getDestinationInstance(), lastResult)
        case .failure:
            callback(nil, lastResult)
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
        
        // As in the main chain: the destination's own plugins may have passed the event through a type that
        // cannot carry the recorded consent, so it is put back from the event handed to this destination.
        if let finalEvent = onProcessedEvent?.restoringSdkOwnedState(from: event),
           let deliverableEvent = self.gateAndRestoreConsentStamp(finalEvent) {
            self.handleEvent(event: deliverableEvent)
        }
    }
    
    var pluginStore: IntegrationPluginStore? {
        return self.analytics?.integrationsController?.integrationPluginStores[self.key]
    }
    
    var pluginChain: PluginChain? {
        return self.pluginStore?.pluginChain
    }
    
    // Not derived from the instance: a lite integration holds one before `create` runs.
    var isDestinationCreated: Bool {
        guard let pluginStore else { return false }
        return pluginStore.destinationState != .pendingCreate
    }
    
    private func applyDefaultPlugins() {
        self.add(plugin: ConsentGatePlugin(key: self.key))
        self.add(plugin: EventFilteringPlugin(key: self.key))
        self.add(plugin: IntegrationOptionsPlugin(key: self.key))
    }
    
    /**
     Applies the consent decision at the handoff boundary, then restores
     `context.consentManagement` to the value the event was created under.

     The destination's own plugins run after `ConsentGatePlugin`, so consent can be revoked after the
     gate has already passed the event. Gating here too makes that guarantee hold all the way to
     delivery rather than only at chain entry.

     Both the live decision and the one recorded at creation are applied, exactly as `ConsentGatePlugin`
     applies them. The gate resolves against a config cache filled by a listener that delivers on
     another queue, so a destination registered before the first source config arrives is built while
     that cache is still `nil`, and every event it sees fails open. This boundary resolves against the
     config the destination was configured with, so it is the first point that can judge those events
     at all — and without the creation-time half, a later grant would deliver an event recorded while
     this destination was denied.

     The stamp is a separate question from the gate: it is restored from the value captured at creation.
     */
    private func gateAndRestoreConsentStamp(_ event: any Event) -> (any Event)? {
        guard let state = analytics?.consentManagementState.value, state.active else { return event }

        let destinationConfig = pluginStore?.destinationConfig
        guard ConsentResolver.resolve(state: state, destinationConfig: destinationConfig) else {
            analytics?.logger.debug(log: "IntegrationPlugin: Dropped event for destination: \(key) — consent was revoked while the event was in the destination chain.")
            return nil
        }

        let allowedWhenCreated = self.capturedConsent(of: event)
            .map { ConsentResolver.resolve(state: $0, destinationConfig: destinationConfig) } ?? true
        guard allowedWhenCreated else {
            analytics?.logger.debug(log: "IntegrationPlugin: Dropped event for destination: \(key) — it was created while this destination was denied.")
            return nil
        }

        return self.consentRestampedEvent(event)
    }

    /**
     The consent this event was created under, or `nil` when it carries none — an event created while
     consent management was inactive, which the caller treats as consented.
     */
    private func capturedConsent(of event: any Event) -> ConsentManagement? {
        guard let stamp = (event as? ReservedContextCapturing)?
            .capturedReservedContext?[ConsentManagement.contextKey] as? [String: Any] else { return nil }

        return ConsentManagement.from(contextStamp: stamp)
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
            analytics?.logger.warn(log: "IntegrationPlugin: Replacing the \"\(stampKey)\" key written by a plugin on destination \(key); the SDK owns this key while consent management is enabled. Migrate to setConsent(_:).")
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
