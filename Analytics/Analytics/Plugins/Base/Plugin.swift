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
@objc
public enum PluginType: Int, CaseIterable {
    /// Plugins that are executed before the main event processing begins.
    case preProcess
    
    /// Plugins that are executed during the main event processing.
    case onProcess
    
    /// Plugins that send processed events to a destination.
    case destination
    
    /// Plugins that are executed after the main event processing has completed.
    case after
    
    /// Plugins that are triggered manually by the user or system.
    case manual
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
    
    /// A reference to the `AnalyticsClient` instance associated with this plugin.
    var analytics: AnalyticsClient? { get set }
    
    /**
     Sets up the plugin with the provided `AnalyticsClient` instance.

     This method is called when the plugin is registered, allowing it to initialize resources or configurations.

     - Parameter analytics: The `AnalyticsClient` instance to associate with the plugin.
     */
    func setup(analytics: AnalyticsClient)
    
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
     Sets up the plugin with the provided `AnalyticsClient` instance.
     */
    func setup(analytics: AnalyticsClient) {
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

 The `EventPlugin` protocol is designed for plugins that need to process events with specific payload structures such as `TrackEvent`, `ScreenEvent`, `GroupEvent`, and `FlushEvent`.
 
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
    
    /**
     Processes a `FlushEvent` payload.
     
     - Parameter payload: The `FlushEvent` payload to be processed.
     - Returns: A modified `Event` or `nil` if the event is to be filtered out.
     */
    func flush(payload: FlushEvent) -> Event?
}

extension EventPlugin {
    
    func identify(payload: IdentifyEvent) -> Event? { payload }
    
    func track(payload: TrackEvent) -> Event? { payload }
    
    func screen(payload: ScreenEvent) -> Event? { payload }
    
    func group(payload: GroupEvent) -> Event? { payload }
    
    func alias(payload: AliasEvent) -> Event? { payload }
    
    func flush(payload: FlushEvent) -> Event? { payload }
    
    /**
     Intercepts the appropriate method based on the event type.

     This method checks the type of the incoming `Event` and delegates it to the corresponding event handler method such as `identify`, `track`, `screen`, `group`, `alias` or `flush`.
     
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
        case let event as FlushEvent:
            return self.flush(payload: event)
        default:
            return nil
        }
    }
}
