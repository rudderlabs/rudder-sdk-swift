//
//  IntegrationPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 08/10/25.
//

import Foundation

protocol StandardIntegration: AnyObject {}

/**
 Base protocol for all integration plugins.

 An integration plugin is a plugin that is responsible for sending events directly
 to a 3rd party destination without sending it to Rudder server first.
 */
public protocol IntegrationPlugin: EventPlugin {
    
    // MARK: - Required Properties
    
    /**
     The key for the destination present in the source config.
     */
    var key: String { get }
    
    // MARK: - Required Methods
    
    /**
     Creates the destination instance. Implement this method for the initialization of destination.
     
     - Parameter destinationConfig: The configuration for the destination as a dictionary.
     - Throws: Any error that occurs during destination creation.
     */
    func create(destinationConfig: [String: Any]) throws
    
    /**
     Returns the instance of the destination which was created.
     
     - Returns: The instance of the destination, or nil if not created.
     */
    func getDestinationInstance() -> Any?
    
    // MARK: - Optional Methods
    
    /**
     This method will be called when the destination configuration is updated.
     The value could be either destination config or empty dictionary.
     
     - Parameter destinationConfig: The updated configuration for the destination.
     */
    func update(destinationConfig: [String: Any])
    
    /**
     Override this method to control the behaviour of flush for this destination.
     */
    func flush()
    
    /**
     Override this method to control the behaviour of reset for this destination.
     */
    func reset()
    
    // MARK: - Plugin Management
    
    /**
     This method adds a plugin to modify the events before sending to this destination.
     
     - Parameter plugin: The plugin to be added.
     */
    func add(plugin: Plugin)
    
    /**
     This method removes a plugin from the destination.
     
     - Parameter plugin: The plugin to be removed.
     */
    func remove(plugin: Plugin)
    
    // MARK: - Destination Ready Callback
    
    /**
     Registers a callback to be invoked when the destination of this plugin is ready.
     
     - Parameter callback: The callback to be invoked when the destination is ready.
     */
    func onDestinationReady(callback: @escaping (Any?, DestinationResult) -> Void)
}

extension IntegrationPlugin {
    private var isStandardIntegration: Bool {
        self is StandardIntegration
    }
    
    internal var isDestinationReady: Bool {
        getDestinationInstance() != nil
    }
}

public extension IntegrationPlugin {
    
    // MARK: - Default Implementations
    
    /**
     Default implementation for update method.
     */
    func update(destinationConfig: [String: Any]) {
        // Default implementation (no-op)
    }
    
    /**
     Default implementation for flush method.
     */
    func flush() {
        // Default implementation (no-op)
    }
    
    /**
     Default implementation for reset method.
     */
    func reset() {
        // Default implementation (no-op)
    }
    
    /**
     Default implementation for add plugin method.
     */
    func add(plugin: Plugin) {
        // Default implementation (no-op)
        // Individual implementations should override this for plugin management
    }
    
    /**
     Default implementation for remove plugin method.
     */
    func remove(plugin: Plugin) {
        // Default implementation (no-op)
        // Individual implementations should override this for plugin management
    }
    
    /**
     Default implementation for onDestinationReady callback.
     */
    func onDestinationReady(callback: @escaping (Any?, DestinationResult) -> Void) {
        if let destinationInstance = getDestinationInstance() {
            callback(destinationInstance, .success)
        } else {
            callback(nil, .failure(NSError(domain: "IntegrationPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Destination \(key) is not ready or not configured."])))
        }
    }
}
