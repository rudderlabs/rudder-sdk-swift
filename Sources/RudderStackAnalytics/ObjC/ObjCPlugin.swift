//
//  ObjCPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

// MARK: - ObjCPlugin
/**
 An Objective-C compatible plugin protocol for extending analytics behavior.

 Conformers can intercept events, perform setup and teardown, and define their plugin type.
 */
@objc(RSSPlugin)
public protocol ObjCPlugin: AnyObject {

    /// The type of plugin (e.g., `preProcess`, `onProcess`, `terminal`, etc.).
    @objc var pluginType: PluginType { get set }

    /**
     Called once when the plugin is registered with the analytics client.

     - Parameter analytics: The analytics client to which this plugin is being attached.
     */
    @objc
    optional func setup(_ analytics: ObjCAnalytics)

    /**
     Intercepts an event before it is sent, allowing for modification or filtering.

     - Parameter event: The event to intercept.
     - Returns: A modified `ObjCEvent`, the same event, or `nil` to drop the event.
     */
    @objc
    optional func intercept(_ event: ObjCEvent) -> ObjCEvent?

    /**
     Called when the plugin is being removed or the analytics client is being deinitialized.
     */
    @objc
    optional func teardown()
}

// MARK: - ObjCPluginAdapter
/**
 An adapter that bridges an Objective-C conforming plugin (`ObjCPlugin`) to the Swift-native `Plugin` protocol.

 This allows Objective-C plugins to be used seamlessly in the analytics pipeline.
 */
final class ObjCPluginAdapter: Plugin {

    /// The type of plugin, bridged from the Objective-C plugin.
    var pluginType: PluginType {
        get { objcPlugin.pluginType }
        set { objcPlugin.pluginType = newValue }
    }

    /// The Swift analytics client reference.
    var analytics: Analytics?

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
     Sets up the plugin using the provided `Analytics`.

     - Parameter analytics: The Swift analytics client managing the plugin lifecycle.
     */
    func setup(analytics: Analytics) {
        self.analytics = analytics
        let objcAnalytics = ObjCAnalytics(analytics: analytics)
        objcPlugin.setup?(objcAnalytics)
    }

    /**
     Intercepts and optionally modifies an event using the wrapped Objective-C plugin.

     - Parameter event: The incoming event to be processed.
     - Returns: The processed event or `nil` to drop the event.
     */
    func intercept(event: Event) -> Event? {
        let objcEvent = createObjCEvent(from: event)
        return objcPlugin.intercept?(objcEvent)?.event ?? event
    }
    
    /**
     Creates the appropriate ObjC event wrapper based on the event type.
     
     - Parameter event: The Swift event to wrap.
     - Returns: The appropriate ObjC event wrapper.
     */
    private func createObjCEvent(from event: Event) -> ObjCEvent {
        switch event {
        case let trackEvent as TrackEvent:
            return ObjCTrackEvent(event: trackEvent)
        case let screenEvent as ScreenEvent:
            return ObjCScreenEvent(event: screenEvent)
        case let groupEvent as GroupEvent:
            return ObjCGroupEvent(event: groupEvent)
        case let identifyEvent as IdentifyEvent:
            return ObjCIdentifyEvent(event: identifyEvent)
        case let aliasEvent as AliasEvent:
            return ObjCAliasEvent(event: aliasEvent)
        default:
            return ObjCEvent(event: event)
        }
    }

    /**
     Tears down the plugin and performs any necessary cleanup.
     */
    func teardown() {
        objcPlugin.teardown?()
    }
}
