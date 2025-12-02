//
//  ObjCIntegrationPlugin.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 28/11/25.
//

import Foundation

// MARK: - ObjCIntegrationPlugin
/**
 An Objective-C compatible protocol that represents an integration plugin.
 
 This protocol provides an Objective-C interface to the Swift `IntegrationPlugin` protocol,
 allowing integration plugins to be implemented and used in Objective-C codebases.
 
 An integration plugin is responsible for sending events directly to a 3rd party destination
 without sending it to Rudder server first.
 */
@objc(RSSIntegrationPlugin)
public protocol ObjCIntegrationPlugin: ObjCEventPlugin {
    
    /**
     The key for the destination present in the source config.
     */
    @objc var key: String { get set }
    
    /**
     Returns the instance of the destination which was created.
     
     - Returns: The instance of the destination, or nil if not created.
     */
    @objc
    func getDestinationInstance() -> Any?
    
    /**
     Creates the destination instance. Override this method for the initialization of destination.
     
     - Parameter destinationConfig: The configuration for the destination as a dictionary.
     - Parameter error: A pointer to an NSError object that will be set if an error occurs.
     - Returns: YES if the destination was created successfully, NO otherwise.
     */
    @objc
    func createWithDestinationConfig(_ destinationConfig: [String: Any], error: NSErrorPointer) -> Bool
    
    /**
     This method will be called when the destination configuration is updated.
     The value could be either destination config or empty dictionary.
     
     - Parameter destinationConfig: The updated configuration for the destination.
     - Parameter error: A pointer to an NSError object that will be set if an error occurs.
     - Returns: YES if the destination was updated successfully, NO otherwise.
     */
    @objc
    optional func updateWithDestinationConfig(_ destinationConfig: [String: Any], error: NSErrorPointer) -> Bool
    
    /**
     Override this method to control the behaviour of flush for this destination.
     */
    @objc
    optional func flush()
    
    /**
     Override this method to control the behaviour of reset for this destination.
     */
    @objc
    optional func reset()
}

// MARK: - ObjCIntegrationPluginAdapter
/**
 An adapter that bridges an Objective-C conforming integration plugin (`ObjCIntegrationPlugin`) to the Swift-native `IntegrationPlugin` protocol.

 This allows Objective-C integration plugins to be used seamlessly in the analytics pipeline.
 */
class ObjCIntegrationPluginAdapter: IntegrationPlugin {
    
    /// The type of plugin, bridged from the Objective-C plugin.
    var pluginType: PluginType {
        get { objcIntegration.pluginType }
        set { objcIntegration.pluginType = newValue }
    }
    
    /// The Swift analytics client reference.
    var analytics: Analytics?
    
    /// The key for the destination present in the source config.
    var key: String {
        get { objcIntegration.key }
        set { objcIntegration.key = newValue }
    }
    
    /// The wrapped Objective-C integration plugin instance.
    private let objcIntegration: ObjCIntegrationPlugin
    
    /**
     Initializes the adapter with a given `ObjCIntegrationPlugin`.

     - Parameter objcPlugin: The Objective-C integration plugin to adapt.
     */
    init(objcIntegration: ObjCIntegrationPlugin) {
        self.objcIntegration = objcIntegration
    }
    
    /**
     Tears down the plugin and performs any necessary cleanup.
     */
    func teardown() {
        objcIntegration.teardown?()
    }
    
    // MARK: - IntegrationPlugin Methods
    
    func getDestinationInstance() -> Any? {
        return objcIntegration.getDestinationInstance()
    }
    
    func create(destinationConfig: [String: Any]) throws {
        var error: NSError?
        let success = objcIntegration.createWithDestinationConfig(destinationConfig, error: &error)
        if let error = error {
            throw error
        }
        if !success {
            throw NSError(domain: "IntegrationPluginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create destination"])
        }
    }
    
    func update(destinationConfig: [String: Any]) throws {
        // Since updateWithDestinationConfig is optional, we can call it directly
        var error: NSError?
        let success = objcIntegration.updateWithDestinationConfig?(destinationConfig, error: &error) ?? true
        if let error = error {
            throw error
        }
        if !success {
            throw NSError(domain: "IntegrationPluginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update destination"])
        }
    }
    
    func flush() {
        objcIntegration.flush?()
    }
    
    func reset() {
        objcIntegration.reset?()
    }
    
    // MARK: - EventPlugin Methods
    
    func identify(payload: IdentifyEvent) {
        let objcEvent = ObjCIdentifyEvent(event: payload)
        objcIntegration.identify?(objcEvent)
    }
    
    func track(payload: TrackEvent) {
        let objcEvent = ObjCTrackEvent(event: payload)
        objcIntegration.track?(objcEvent)
    }
    
    func screen(payload: ScreenEvent) {
        let objcEvent = ObjCScreenEvent(event: payload)
        objcIntegration.screen?(objcEvent)
    }
    
    func group(payload: GroupEvent) {
        let objcEvent = ObjCGroupEvent(event: payload)
        objcIntegration.group?(objcEvent)
    }
    
    func alias(payload: AliasEvent) {
        let objcEvent = ObjCAliasEvent(event: payload)
        objcIntegration.alias?(objcEvent)
    }
}

// MARK: - Analytics Extension for ObjC Integration Plugins

extension ObjCAnalytics {
    /**
     Adds an Objective-C integration plugin to the analytics instance.
     
     - Parameter integration: The Objective-C integration plugin to add.
     */
    @objc(addIntegration:)
    public func add(integration: ObjCIntegrationPlugin) {
        let isStandardIntegration = integration is ObjCStandardIntegration
        let adapter = isStandardIntegration ? ObjCStandardIntegrationAdapter(objcIntegration: integration) : ObjCIntegrationPluginAdapter(objcIntegration: integration)
        analytics.add(plugin: adapter)
    }
}
