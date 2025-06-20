//
//  Plugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - PluginType

/**
 Represents the type of plugin within the analytics system.

 The `PluginType` enum defines the various stages or categories of plugins that can be used in the event processing pipeline.

 - Conforms to: `CaseIterable`
 */
@objc(RSAPluginType)
public enum PluginType: Int, CaseIterable {
    /// Plugins of this type are executed before any event processing begins. Useful for pre-processing events or adding context data.
    case preProcess
    
    /// Plugins of this type are executed as the first level of event processing. Useful for applying transformations or validations early in the pipeline.
    case onProcess
    
    /// Plugins of this type are executed at the end when events are about to be passed off to their destinations. Typically used for modifying events specifically for certain destinations.
    case terminal
    
    /// Plugins of this type are executed only when called manually. For example, session-based plugins that trigger on specific user actions.
    case utility
}

// MARK: - Plugin

/**
 Defines the structure and behavior of plugins within the analytics system.

 The `Plugin` protocol outlines the requirements for creating custom plugins that can be integrated into the analytics pipeline. Plugins enable users to modify, enhance, or extend event processing at various stages.

 - Conforms to: `AnyObject`
 */
public protocol Plugin: AnyObject {
    
    /// The type of the plugin, indicating where it fits in the processing pipeline.
    var pluginType: PluginType { get set }
    
    /// A reference to the `Analytics` instance associated with this plugin.
    var analytics: Analytics? { get set }
    
    /**
     Sets up the plugin with the provided `Analytics` instance.

     This method is called when the plugin is registered, allowing it to initialize resources or configurations.

     - Parameter analytics: The `Analytics` instance to associate with the plugin.
     */
    func setup(analytics: Analytics)
    
    /**
     Intercepts the plugin's logic on the provided event.

     This method is called during the event processing pipeline. Plugins can modify, filter, or enrich the event as needed.

     - Parameter event: The `Event` event being processed.
     - Returns: The modified `Event` event, or `nil` to indicate the event should be filtered out.
     */
    func intercept(event: Event) -> Event?
    
    /**
     Cleans up resources used by the plugin.

     This method is called when the plugin is being removed or the analytics system is shutting down.
     */
    func teardown()
}

/**
 Provides default implementations for the `Plugin` protocol methods.
 */
public extension Plugin {
    /**
     Sets up the plugin with the provided `Analytics` instance.
     */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /**
     Intercepts the plugin's logic on the provided event.
     */
    func intercept(event: Event) -> Event? {
        event
    }
    
    /**
     Cleans up resources used by the plugin.
     */
    func teardown() {
        /* Default implementation (no-op) */
    }
}

// MARK: - EventPlugin

/**
 Extends the `Plugin` protocol to handle specific types of event payloads.

 The `EventPlugin` protocol is designed for plugins that need to process events with specific payload structures such as `TrackEvent`, `ScreenEvent` and `GroupEvent`.
 
 It builds upon the `Plugin` protocol, adding event-specific methods to facilitate targeted processing.

 - Conforms to: `Plugin`
 */
protocol EventPlugin: Plugin {
    
    /**
     Processes a `IdentifyEvent` payload.
     
     - Parameter payload: The `IdentifyEvent` payload to be processed.
     - Returns: A modified `Event` or `nil` if the event is to be filtered out.
     */
    func identify(payload: IdentifyEvent) -> Event?
    
    /**
     Processes a `TrackEvent` payload.
     
     - Parameter payload: The `TrackEvent` payload to be processed.
     - Returns: A modified `Event` or `nil` if the event is to be filtered out.
     */
    func track(payload: TrackEvent) -> Event?
    
    /**
     Processes a `ScreenEvent` payload.
     
     - Parameter payload: The `ScreenEvent` payload to be processed.
     - Returns: A modified `Event` or `nil` if the event is to be filtered out.
     */
    func screen(payload: ScreenEvent) -> Event?
    
    /**
     Processes a `GroupEvent` payload.
     
     - Parameter payload: The `GroupEvent` payload to be processed.
     - Returns: A modified `Event` or `nil` if the event is to be filtered out.
     */
    func group(payload: GroupEvent) -> Event?
    
    /**
     Processes a `AliasEvent` payload.
     
     - Parameter payload: The `AliasEvent` payload to be processed.
     - Returns: A modified `Event` or `nil` if the event is to be filtered out.
     */
    func alias(payload: AliasEvent) -> Event?
}

extension EventPlugin {
    
    func identify(payload: IdentifyEvent) -> Event? { payload }
    
    func track(payload: TrackEvent) -> Event? { payload }
    
    func screen(payload: ScreenEvent) -> Event? { payload }
    
    func group(payload: GroupEvent) -> Event? { payload }
    
    func alias(payload: AliasEvent) -> Event? { payload }
        
    /**
     Intercepts the appropriate method based on the event type.

     This method checks the type of the incoming `Event` and delegates it to the corresponding event handler method such as `identify`, `track`, `screen`, `group` or `alias`.
     
     If the event type is unknown, it returns `nil`.

     - Parameter event: The event to be processed.
     - Returns: A processed `Event`, or `nil` if the event type is unsupported.
     */
    func intercept(event: any Event) -> (any Event)? {
        switch event {
        case let event as IdentifyEvent:
            return self.identify(payload: event)
        case let event as TrackEvent:
            return self.track(payload: event)
        case let event as ScreenEvent:
            return self.screen(payload: event)
        case let event as GroupEvent:
            return self.group(payload: event)
        case let event as AliasEvent:
            return self.alias(payload: event)
        default:
            return nil
        }
    }
}
