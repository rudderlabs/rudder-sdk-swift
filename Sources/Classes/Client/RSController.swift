//
//  Timeline.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

// MARK: - Main Timeline

public class RSController {
    internal let plugins: [PluginType: Mediator]
    
    public init() {
        self.plugins = [
            .before: Mediator(),
            .enrichment: Mediator(),
            .destination: Mediator(),
            .after: Mediator(),
            .utility: Mediator()
        ]
    }
    
    @discardableResult
    internal func process<E: RSMessage>(incomingEvent: E) -> E? {
        // apply .before and .enrichment types first ...
        let beforeResult = applyPlugins(type: .before, event: incomingEvent)
        // .enrichment here is akin to source middleware in the old analytics-ios.
//        let enrichmentResult = applyPlugins(type: .enrichment, event: beforeResult)
        
        // once the event enters a destination, we don't want
        // to know about changes that happen there. those changes
        // are to only be received by the destination.
        _ = applyPlugins(type: .destination, event: beforeResult)
        
        // apply .after plugins ...
        let afterResult = applyPlugins(type: .after, event: beforeResult)

        return afterResult
    }
    
    // helper method used by DestinationPlugins and Timeline
    internal func applyPlugins<E: RSMessage>(type: PluginType, event: E?) -> E? {
        var result: E? = event
        if let mediator = plugins[type], let e = event {
            result = mediator.execute(event: e)
        }
        return result
    }
}

internal class Mediator {
    internal func add(plugin: RSPlugin) {
        plugins.append(plugin)
        if let option = plugin.client?.serverConfig {
            plugin.update(serverConfig: option, type: .initial)
        }
    }
    
    internal func remove(plugin: RSPlugin) {
        plugins.removeAll { (storedPlugin) -> Bool in
            return plugin === storedPlugin
        }
    }

    internal var plugins = [RSPlugin]()
    internal func execute<T: RSMessage>(event: T) -> T? {
        var result: T? = event
        
        plugins.forEach { (plugin) in
            if let r = result {
                // Drop the event return because we don't care about the
                // final result.
                if plugin is RSDestinationPlugin {
                    _ = plugin.execute(event: r)
                } else {
                    result = plugin.execute(event: r)
                }
            }
        }
        
        return result
    }
}

// MARK: - Plugin Support

extension RSController {
    internal func apply(_ closure: (RSPlugin) -> Void) {
        for type in PluginType.allCases {
            if let mediator = plugins[type] {
                mediator.plugins.forEach { (plugin) in
                    closure(plugin)
                    if let destPlugin = plugin as? RSDestinationPlugin {
                        destPlugin.apply(closure: closure)
                    }
                }
            }
        }
    }
    
    internal func add(plugin: RSPlugin) {
        if let mediator = plugins[plugin.type] {
            mediator.add(plugin: plugin)
        }
    }
    
    internal func remove(plugin: RSPlugin) {
        // remove all plugins with this name in every category
        for type in PluginType.allCases {
            if let mediator = plugins[type] {
                let toRemove = mediator.plugins.filter { (storedPlugin) -> Bool in
                    return plugin === storedPlugin
                }
                toRemove.forEach { (plugin) in
                    plugin.shutdown()
                    mediator.remove(plugin: plugin)
                }
            }
        }
    }
    
    internal func find<T: RSPlugin>(pluginType: T.Type) -> T? {
        var found = [RSPlugin]()
        for type in PluginType.allCases {
            if let mediator = plugins[type] {
                found.append(contentsOf: mediator.plugins.filter { (plugin) -> Bool in
                    return plugin is T
                })
            }
        }
        return found.first as? T
    }
}

// MARK: - Plugin Timeline Execution

extension RSEventPlugin {
    public func execute<T: RSMessage>(event: T?) -> T? {
        var result: T? = event
        switch result {
        case let r as IdentifyMessage:
            result = self.identify(event: r) as? T
        case let r as TrackMessage:
            result = self.track(event: r) as? T
        case let r as ScreenMessage:
            result = self.screen(event: r) as? T
        case let r as AliasMessage:
            result = self.alias(event: r) as? T
        case let r as GroupMessage:
            result = self.group(event: r) as? T
        default:
            break
        }
        return result
    }

    // Default implementations that forward the event. This gives plugin
    // implementors the chance to interject on an event.
    public func identify(event: IdentifyMessage) -> IdentifyMessage? {
        return event
    }
    
    public func track(event: TrackMessage) -> TrackMessage? {
        return event
    }
    
    public func screen(event: ScreenMessage) -> ScreenMessage? {
        return event
    }
    
    public func group(event: GroupMessage) -> GroupMessage? {
        return event
    }
    
    public func alias(event: AliasMessage) -> AliasMessage? {
        return event
    }
    
    public func flush() { }
    public func reset() { }
}

// MARK: - Destination Timeline

extension RSDestinationPlugin {
    public func execute<T: RSMessage>(event: T?) -> T? {
        var result: T? = event
        if let r = result {
            result = self.process(incomingEvent: r)
        }
        return result
    }
    
    internal func isDestinationEnabled(event: RSMessage) -> Bool {
        var customerDisabled = false
        
        if let integration = event.integrations?.first(where: { key, _ in
            return key == self.key
        }), integration.value == false {
            customerDisabled = true
        }
        
        var hasSettings = false        
        if let destinations = client?.serverConfig?.destinations {
            if let destination = destinations.first(where: { $0.destinationDefinition?.displayName == self.key }), destination.enabled {
                hasSettings = true
            }
        }
        
        return (hasSettings == true && customerDisabled == false)
    }

    internal func process<E: RSMessage>(incomingEvent: E) -> E? {
        // This will process plugins (think destination middleware) that are tied
        // to this destination.
        
        var result: E?
        
        if isDestinationEnabled(event: incomingEvent) {
            // apply .before and .enrichment types first ...
            let beforeResult = controller.applyPlugins(type: .before, event: incomingEvent)
            let enrichmentResult = controller.applyPlugins(type: .enrichment, event: beforeResult)
            
            // now we execute any overrides we may have made.  basically, the idea is to take an
            // incoming event, like identify, and map it to whatever is appropriate for this destination.
            var destinationResult: E?
            switch enrichmentResult {
            case let e as IdentifyMessage:
                destinationResult = identify(event: e) as? E
            case let e as TrackMessage:
                destinationResult = track(event: e) as? E
            case let e as ScreenMessage:
                destinationResult = screen(event: e) as? E
            case let e as GroupMessage:
                destinationResult = group(event: e) as? E
            case let e as AliasMessage:
                destinationResult = alias(event: e) as? E
            default:
                break
            }
            
            // apply .after plugins ...
            result = controller.applyPlugins(type: .after, event: destinationResult)
        }
        
        return result
    }
}
