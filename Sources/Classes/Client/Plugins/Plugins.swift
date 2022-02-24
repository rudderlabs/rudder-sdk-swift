//
//  Plugins.swift
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

protocol Plugin: AnyObject {
    var type: PluginType { get }
    var analytics: RSClient? { get set }
    
    func configure(analytics: RSClient)
    func update(serverConfig: RSServerConfig, type: UpdateType)
    func execute<T: RSMessage>(event: T?) -> T?
    func shutdown()
}

extension Plugin {
    func execute<T: RSMessage>(event: T?) -> T? {
        // do nothing.
        return event
    }
    
    func update(serverConfig: RSServerConfig, type: UpdateType) {
        // do nothing by default, user can override.
    }

    func shutdown() {
        // do nothing by default, user can override.
    }
    
    func configure(analytics: RSClient) {
        self.analytics = analytics
    }
}

protocol EventPlugin: Plugin {
    func identify(event: IdentifyMessage) -> IdentifyMessage?
    func track(event: TrackMessage) -> TrackMessage?
    func group(event: GroupMessage) -> GroupMessage?
    func alias(event: AliasMessage) -> AliasMessage?
    func screen(event: ScreenMessage) -> ScreenMessage?
    func reset()
    func flush()
}

protocol DestinationPlugin: EventPlugin {
    var key: String { get }
    var timeline: Timeline { get }
    func add(plugin: Plugin) -> Plugin
    func apply(closure: (Plugin) -> Void)
    func remove(plugin: Plugin)
}

protocol UtilityPlugin: EventPlugin { }

// For internal platform-specific bits
internal protocol PlatformPlugin: Plugin { }


// MARK: - Adding/Removing Plugins

extension DestinationPlugin {
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
    func apply(closure: (Plugin) -> Void) {
        timeline.apply(closure)
    }
    
    /**
     Adds a new plugin to the currently loaded set.
     
     - Parameter plugin: The plugin to be added.
     - Returns: Returns the name of the supplied plugin.
     
     */
    @discardableResult
    func add(plugin: Plugin) -> Plugin {
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
    func remove(plugin: Plugin) {
        timeline.remove(plugin: plugin)
    }
}
