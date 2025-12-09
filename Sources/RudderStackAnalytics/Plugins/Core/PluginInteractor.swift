//
//  PluginInteractor.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/08/24.
//

import Foundation

// MARK: - PluginInteractor
class PluginInteractor {
    
    @Synchronized var pluginList = [Plugin]()
    
    func add(plugin: Plugin) {
        self.pluginList.append(plugin)
    }
    
    func remove(plugin: Plugin) {
        self.pluginList.removeAll { $0 === plugin }
    }
    
    func removeAll() {
        pluginList.removeAll()
    }
    
    func execute(_ event: Event) -> Event? {
        var result: Event? = event
        self.pluginList.forEach {
            if let processing = result {
                result = $0.intercept(event: processing)
            }
        }
        return result
    }
    
    func apply(closure: PluginClosure) {
        self.pluginList.forEach { closure($0) }
    }
    
    func find<T: Plugin>(_ pluginClass: T.Type) -> T? {
        return self.findAll(pluginClass).first
    }
    
    func findAll<T: Plugin>(_ pluginClass: T.Type) -> [T] {
        return pluginList.compactMap { $0 as? T }
    }
}
