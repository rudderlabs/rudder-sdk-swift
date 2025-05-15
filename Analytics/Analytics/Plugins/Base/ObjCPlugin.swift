//
//  ObjCPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 15/05/25.
//

import Foundation

// MARK: - ObjCPlugin
/**
 An Objective-C compatible plugin protocol for extending analytics behavior.

 Conformers can intercept events, perform setup and teardown, and define their plugin type.
 */
@objc
public protocol ObjCPlugin: AnyObject {
    
    /** The type of plugin (e.g., `preProcess`, `onProcess`, `destination`, etc.). */
    var pluginType: PluginType { get set }
    
    /**
     Called once when the plugin is registered with the analytics client.
     
     - Parameter analytics: The analytics client to which this plugin is being attached.
     */
    func setup(_ analytics: AnalyticsClient)
    
    /**
     Intercepts an event before it is sent, allowing for modification or filtering.
     
     - Parameter event: The event to intercept.
     - Returns: A modified `ObjCEvent`, the same event, or `nil` to drop the event.
     */
    func intercept(_ event: ObjCEvent) -> ObjCEvent?
    
    /**
     Called when the plugin is being removed or the analytics client is being deinitialized.
     
     Use this to clean up resources or perform final operations.
     */
    func teardown()
}

// MARK: - ObjCPluginAdapter
/**
 An adapter that bridges an Objective-C conforming plugin (`ObjCPlugin`) to the Swift-native `Plugin` protocol.

 This allows Objective-C plugins to be used seamlessly in the analytics pipeline.
 */
final class ObjCPluginAdapter: Plugin {

    /** The type of plugin (e.g., `preProcess`, `onProcess`, `destination`, etc.). */
    var pluginType: PluginType {
        get { objcPlugin.pluginType }
        set { objcPlugin.pluginType = newValue }
    }

    /** A reference to the analytics client this plugin is attached to. */
    var analytics: AnalyticsClient?

    /// The wrapped Objective-C plugin instance.
    private let objcPlugin: ObjCPlugin

    /**
     Initializes the adapter with a given `ObjCPlugin`.

     - Parameter objcPlugin: The Objective-C plugin to adapt.
     */
    init(objcPlugin: ObjCPlugin) {
        self.objcPlugin = objcPlugin
    }

    /**
     Sets up the plugin using the provided `AnalyticsClient`.

     - Parameter analytics: The analytics client managing the plugin lifecycle.
     */
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        objcPlugin.setup(analytics)
    }

    /**
     Intercepts and optionally modifies an event using the wrapped Objective-C plugin.

     - Parameter event: The incoming event to be processed.
     - Returns: The processed event or `nil` to drop the event.
     */
    func intercept(event: Event) -> Event? {
        let wrapper = ObjCEvent(event: event)
        return objcPlugin.intercept(wrapper)?.event
    }

    /**
     Tears down the plugin and performs any necessary cleanup.
     */
    func teardown() {
        objcPlugin.teardown()
    }
}
