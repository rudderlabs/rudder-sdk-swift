//
//  RSPlugins.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

/**
 PluginType specifies where in the chain a given plugin is to be executed.
 */
enum PluginType: Int, CaseIterable {
    /// Executed before event processing begins.
    case before
    /// Executed as the first level of event processing.
    case enrichment
    /// Executed as events begin to pass off to destinations.
    case destination
    /// Executed after all event processing is completed.  This can be used to perform cleanup operations, etc.
    case after
    /// Executed only when called manually, such as Logging.
    case utility
}

enum UpdateType {
    case initial
    case refresh
}

protocol RSPlugin: AnyObject {
    var type: PluginType { get }
    var analytics: RSClient? { get set }
    
    func configure(analytics: RSClient)
    func update(serverConfig: RSServerConfig, type: UpdateType)
    func execute<T: RSMessage>(event: T?) -> T?
    func shutdown()
}

extension RSPlugin {
    func execute<T: RSMessage>(event: T?) -> T? {
        return event
    }
    
    func update(serverConfig: RSServerConfig, type: UpdateType) { }

    func shutdown() { }
    
    func configure(analytics: RSClient) {
        self.analytics = analytics
    }
}

protocol RSEventPlugin: RSPlugin {
    func identify(event: IdentifyMessage) -> IdentifyMessage?
    func track(event: TrackMessage) -> TrackMessage?
    func group(event: GroupMessage) -> GroupMessage?
    func alias(event: AliasMessage) -> AliasMessage?
    func screen(event: ScreenMessage) -> ScreenMessage?
    func reset()
    func flush()
}

protocol RSDestinationPlugin: RSEventPlugin {
    var key: String { get }
    var timeline: RSController { get }
    func add(plugin: RSPlugin) -> RSPlugin
    func apply(closure: (RSPlugin) -> Void)
    func remove(plugin: RSPlugin)
}

protocol RSUtilityPlugin: RSEventPlugin { }

// For internal platform-specific bits
internal protocol PlatformPlugin: RSPlugin { }

// MARK: - Adding/Removing Plugins

extension RSDestinationPlugin {
    func configure(analytics: RSClient) {
        self.analytics = analytics
        apply { plugin in
            plugin.configure(analytics: analytics)
        }
    }
    
    /**
     Applies the supplied closure to the currently loaded set of plugins.
     
     - Parameter closure: A closure that takes an plugin to be operated on as a parameter.
     
     */
    func apply(closure: (RSPlugin) -> Void) {
        timeline.apply(closure)
    }
    
    /**
     Adds a new plugin to the currently loaded set.
     
     - Parameter plugin: The plugin to be added.
     - Returns: Returns the name of the supplied plugin.
     
     */
    @discardableResult
    func add(plugin: RSPlugin) -> RSPlugin {
        if let analytics = self.analytics {
            plugin.configure(analytics: analytics)
        }
        timeline.add(plugin: plugin)
        return plugin
    }
    
    /**
     Removes and unloads plugins with a matching name from the system.
     
     - Parameter pluginName: An plugin name.
     */
    func remove(plugin: RSPlugin) {
        timeline.remove(plugin: plugin)
    }
}
