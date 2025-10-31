//
//  PluginChain.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/08/24.
//

import Foundation

// MARK: - Typealiases
typealias PluginClosure = (Plugin) -> Void

// MARK: - PluginChain
class PluginChain {
    
    private var pluginList = [PluginType: PluginInteractor]()
    var analytics: Analytics
    
    init(analytics: Analytics) {
        self.analytics = analytics
        PluginType.allCases.forEach { self.pluginList[$0] = PluginInteractor() }
    }
    
    func process(event: Event) {        
        let preProcessedResult = self.applyPlugins(pluginType: .preProcess, event: event)
        let onProcessedResult = self.applyPlugins(pluginType: .onProcess, event: preProcessedResult)
        
        self.applyPlugins(pluginType: .terminal, event: onProcessedResult)
    }
    
    func add(plugin: Plugin) {
        plugin.setup(analytics: self.analytics)
        self.pluginList[plugin.pluginType]?.add(plugin: plugin)
    }
    
    func remove(plugin: Plugin) {
        self.pluginList.values.forEach {
            $0.remove(plugin: plugin)
            plugin.teardown()
        }
    }
    
    func apply(closure: PluginClosure) {
        self.pluginList.values.forEach {
            $0.apply(closure: closure)
        }
    }
    
    func removeAll() {
        apply { $0.teardown() }
        pluginList.forEach { _, mediator in
            mediator.removeAll()
        }
    }
    
    func find<T: Plugin>(type: T.Type) -> T? {
        for pluginType in PluginType.allCases {
            if let mediator = pluginList[pluginType],
               let found = mediator.find(type) {
                return found
            }
        }
        return nil
    }
}

extension PluginChain {
    
    /**
     Applies plugins of a specific type to an event.

     - Parameter pluginType: The type of plugins to apply
     - Parameter event: The event to process
     - Returns: The processed event or nil
     */
    @discardableResult
    func applyPlugins(pluginType: PluginType, event: Event?) -> Event? {
        guard let mediator = self.pluginList[pluginType] else { return event }
        return self.applyPlugins(mediator: mediator, event: event)
    }
    
    @discardableResult
    func applyPlugins(mediator: PluginInteractor, event: Event?) -> Event? {
        guard let event else { return nil }
        return mediator.execute(event)
    }
}

extension PluginChain {
    func find(key: String) -> IntegrationPlugin? {
        if let mediator = pluginList[.terminal] {
            return mediator.pluginList.first { plugin in
                guard let integrationPlugin = plugin as? IntegrationPlugin else { return false }
                return integrationPlugin.key == key
            } as? IntegrationPlugin
        }
        return nil
    }
}
