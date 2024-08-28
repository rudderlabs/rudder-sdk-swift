//
//  PluginChain.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/08/24.
//

import Foundation

// MARK: - PluginChain
class PluginChain {
    
    private var pluginList = [PluginType: PluginInteractor]()
    var analytics: Analytics
    
    init(analytics: Analytics) {
        self.analytics = analytics
        PluginType.allCases.forEach { self.pluginList[$0] = PluginInteractor() }
    }
    
    func process(event: MessageEvent) {
        guard !self.analytics.configuration.optOut else { return }
        
        let preProcessedResult = self.applyPlugins(pluginType: .preProcess, event: event)
        let onProcessedResult = self.applyPlugins(pluginType: .onProcess, event: preProcessedResult)
        
        self.applyPlugins(pluginType: .integrations, event: onProcessedResult)
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
}

// MARK: - Private functions
extension PluginChain {
    @discardableResult
    private func applyPlugins(pluginType: PluginType, event: MessageEvent) -> MessageEvent {
        guard let mediator = self.pluginList[pluginType] else { return event }
        return self.applyPlugins(mediator: mediator, event: event)
    }
    
    @discardableResult
    private func applyPlugins(mediator: PluginInteractor, event: MessageEvent) -> MessageEvent {
        return mediator.execute(event)
    }
}
