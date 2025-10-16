//
//  IntegrationPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation

public typealias IntegrationCallback = (Any?, DestinationResult) -> Void

protocol StandardPlugin : AnyObject {}

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
    func update(destinationConfig: [String: Any]) throws {}
    func flush() {}
    func reset() {}
}

public extension IntegrationPlugin {
  
    func add(plugin: Plugin) {
        self.pluginChain?.add(plugin: plugin)
    }
    
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
                callback(destinationInstance, .success)
            } else {
                callback(nil, .failure(NSError(domain: "IntegrationPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Destination \(key) is absent or disabled in dashboard."])))
            }
        } else {
            // Store callback for later notification when destination becomes ready
            pluginStore.destinationReadyCallbacks.append(callback)
        }
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let pluginStore else { return event }
        if pluginStore.isDestinationReady {
            // Apply plugin chain processing
                        
            let preProcessedEvent = pluginChain?.applyPlugins(pluginType: .preProcess,event: event)
            let onProcessedEvent = pluginChain?.applyPlugins(pluginType: .onProcess,event: preProcessedEvent)
            
            // Handle the event after plugin processing
            if let finalEvent = onProcessedEvent {
                self.handleEvent(event: finalEvent)
            }
        }
        return event
    }
}

extension IntegrationPlugin {
    var pluginStore: IntegrationPluginStore? {
        return self.analytics?.integrationsController?.integrationPluginStores[self.key]
    }
    
    var pluginChain: PluginChain? {
        return self.pluginStore?.pluginChain
    }
}
