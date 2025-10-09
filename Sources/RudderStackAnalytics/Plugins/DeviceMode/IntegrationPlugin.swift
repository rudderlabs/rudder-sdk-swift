//
//  IntegrationPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 08/10/25.
//

import Foundation

protocol StandardIntegration: AnyObject {}

/**
 Base class for all integration plugins.

 An integration plugin is a plugin that is responsible for sending events directly
 to a 3rd party destination without sending it to Rudder server first.
 */
open class IntegrationPlugin: EventPlugin {
    
    // MARK: - Final Properties
    
    public final var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    
    // MARK: - Private State
    
    private var pluginChain: PluginChain?
    private var pluginList: [Plugin] = []
    private var destinationReadyCallbacks: [(Any?, DestinationResult) -> Void] = []
    private var isStandardIntegration: Bool = true
    
    private var isPluginSetup = false
    internal var isDestinationReady = false
    
    // MARK: - Abstract Properties (must be overridden)
    
    /**
     The key for the destination present in the source config.
     */
    open var key: String {
        fatalError("Subclasses must override the 'key' property")
    }
    
    // MARK: - Abstract Methods (must be overridden)
    
    /**
     Creates the destination instance. Override this method for the initialization of destination.
     
     - Parameter destinationConfig: The configuration for the destination as a dictionary.
     - Throws: Any error that occurs during destination creation.
     */
    open func create(destinationConfig: [String: Any]) throws {
        fatalError("Subclasses must override the 'create(destinationConfig:)' method")
    }
    
    /**
     Returns the instance of the destination which was created.
     
     - Returns: The instance of the destination, or nil if not created.
     */
    open func getDestinationInstance() -> Any? {
        fatalError("Subclasses must override the 'getDestinationInstance()' method")
    }
    
    // MARK: - Open Methods (can be overridden)
    
    /**
     This method will be called when the destination configuration is updated.
     The value could be either destination config or empty dictionary.
     
     - Parameter destinationConfig: The updated configuration for the destination.
     - Throws: Any error that occurs during destination updation.
     */
    open func update(destinationConfig: [String: Any]) throws {
        // Default implementation (no-op)
    }
    
    /**
     Override this method to control the behaviour of flush for this destination.
     */
    open func flush() {
        // Default implementation (no-op)
    }
    
    /**
     Override this method to control the behaviour of reset for this destination.
     */
    open func reset() {
        // Default implementation (no-op)
    }
    
    // MARK: - Plugin Management
    
    /**
     This method adds a plugin to modify the events before sending to this destination.
     
     - Parameter plugin: The plugin to be added.
     */
    open func add(plugin: Plugin) {
        if isPluginSetup {
            pluginChain?.add(plugin: plugin)
        } else {
            pluginList.append(plugin)
        }
    }
    
    /**
     This method removes a plugin from the destination.
     
     - Parameter plugin: The plugin to be removed.
     */
    open func remove(plugin: Plugin) {
        pluginList.removeAll { $0 === plugin }
        if isPluginSetup {
            pluginChain?.remove(plugin: plugin)
        }
    }
    
    // MARK: - Destination Ready Callback
    
    /**
     Registers a callback to be invoked when the destination of this plugin is ready.
     
     - Parameter callback: The callback to be invoked when the destination is ready.
     */
    public final func onDestinationReady(callback: @escaping (Any?, DestinationResult) -> Void) {
        if let destinationInstance = getDestinationInstance() {
            if isDestinationReady {
                callback(destinationInstance, .success)
            } else {
                callback(nil, .failure(NSError(domain: "IntegrationPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Destination \(key) is absent or disabled in dashboard."])))
            }
        } else {
            // Store callback for later notification when destination becomes ready
            destinationReadyCallbacks.append(callback)
        }
    }
    
    // MARK: - Final Override Methods
    
    public final func setup(analytics: Analytics) {
        self.analytics = analytics
        isStandardIntegration = self is StandardIntegration
        pluginChain = PluginChain(analytics: analytics)
        isPluginSetup = true
        
        // Apply any plugins that were added before setup
        pluginList.forEach { plugin in
            pluginChain?.add(plugin: plugin)
        }
        pluginList.removeAll()
        
        applyDefaultPlugins()
    }
    
    public final func intercept(event: Event) -> Event? {
        if isDestinationReady {
            // Apply plugin chain processing
            let preProcessedEvent = pluginChain?.applyPlugins(pluginType: .preProcess,event: event)
            let onProcessedEvent = pluginChain?.applyPlugins(pluginType: .onProcess,event: preProcessedEvent)
            
            // Handle the event after plugin processing
            if let finalEvent = onProcessedEvent {
                handleEvent(finalEvent)
            }
        }
        return event
    }
    
    open func teardown() {
        destinationReadyCallbacks.removeAll()
        pluginList.removeAll()
        if isPluginSetup {
            pluginChain?.removeAll()
        }
        pluginChain = nil
    }
    
    // MARK: - Internal Lifecycle Management
    
    /**
     Internal method to initialize the destination with source configuration.
     
     - Parameter sourceConfig: The source configuration containing destination settings.
     */
    internal func initDestination(sourceConfig: SourceConfig) {
        if let destinationConfig = isDestinationConfigured(sourceConfig: sourceConfig) {
            safelyInitOrUpdateAndNotify(destinationConfig: destinationConfig)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func isDestinationConfigured(sourceConfig: SourceConfig) -> [String: Any]? {
        if !isStandardIntegration {
            return [:]
        }
        
        if let configDestination = findDestination(sourceConfig: sourceConfig) {
            if !configDestination.isDestinationEnabled {
                let errorMessage = "Destination \(key) is disabled in dashboard. No events will be sent to this destination."
                LoggerAnalytics.warn("IntegrationPlugin: \(errorMessage)")
                safelyUpdateOnFailureAndNotify(error: NSError(domain: "IntegrationPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                return nil
            }
            return configDestination.destinationConfig.mapValues { $0.value }
        } else {
            let errorMessage = "Destination \(key) not found in the source config. No events will be sent to this destination."
            LoggerAnalytics.warn("IntegrationPlugin: \(errorMessage)")
            safelyUpdateOnFailureAndNotify(error: NSError(domain: "IntegrationPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            return nil
        }
    }
    
    private func findDestination(sourceConfig: SourceConfig) -> Destination? {
        return sourceConfig.source.destinations.first { $0.destinationDefinition.name == key }
    }
    
    private func safelyInitOrUpdateAndNotify(destinationConfig: [String: Any]) {
        if getDestinationInstance() == nil {
            safelyCreateAndNotify(destinationConfig: destinationConfig)
        } else {
            safelyUpdateAndNotify(destinationConfig: destinationConfig)
        }
    }
    
    private func safelyCreateAndNotify(destinationConfig: [String: Any]) {
        do {
            try create(destinationConfig: destinationConfig)
            LoggerAnalytics.debug("IntegrationPlugin: Destination \(key) created successfully.")
            self.isDestinationReady = true
            notifyCallbacks(result: .success)
        } catch {
            LoggerAnalytics.error("IntegrationPlugin: Error: \(error.localizedDescription) creating destination \(key).")
            self.isDestinationReady = false
            notifyCallbacks(result: .failure(error))
        }
    }
    
    private func safelyUpdateOnFailureAndNotify(error: Error) {
        safelyUpdateAndApplyBlock(destinationConfig: [:]) {
            LoggerAnalytics.debug("IntegrationPlugin: Destination \(key) updated with empty destinationConfig.")
            self.isDestinationReady = false
            notifyCallbacks(result: .failure(error))
        }
    }
    
    private func safelyUpdateAndNotify(destinationConfig: [String: Any]) {
        safelyUpdateAndApplyBlock(destinationConfig: destinationConfig) {
            LoggerAnalytics.debug("IntegrationPlugin: Destination \(key) updated with destinationConfig: \(destinationConfig).")
            self.isDestinationReady = true
            notifyCallbacks(result: .success)
        }
    }
    
    private func safelyUpdateAndApplyBlock(destinationConfig: [String: Any], block: () -> Void) {
        do {
            if isStandardIntegration {
                try update(destinationConfig: destinationConfig)
                block()
            }
        } catch {
            LoggerAnalytics.error("IntegrationPlugin: Error: \(error.localizedDescription) updating destination \(key).")
            self.isDestinationReady = false
            notifyCallbacks(result: .failure(error))
        }
    }
    
    private func notifyCallbacks(result: DestinationResult) {
        let callbacks = destinationReadyCallbacks
        destinationReadyCallbacks.removeAll()
        
        callbacks.forEach { callback in
            callback(getDestinationInstance(), result)
        }
    }
    
    private func applyDefaultPlugins() {
        // TODO: Add EventFilteringPlugin and IntegrationOptionsPlugin
        // add(EventFilteringPlugin(key))
        // add(IntegrationOptionsPlugin(key))
    }
}
