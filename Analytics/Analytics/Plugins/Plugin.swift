//
//  Plugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

@objc
public enum PluginType: Int, CaseIterable {
    case preProcess, onProcess, integrations, utility
}

protocol Plugin: AnyObject {
    var pluginType: PluginType { get set }
    var analytics: Analytics? { get set }
    
    func setup(analytics: Analytics)
    func execute(event: MessageEvent) -> MessageEvent
    
    func teardown()
}

extension Plugin {
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func execute(event: MessageEvent) -> MessageEvent{
        return event
    }
    
    func teardown() {}
}


class POCPlugin: Plugin {
    var analytics: Analytics?
    
    var pluginType: PluginType = .preProcess
        
    func execute(event: MessageEvent) -> MessageEvent {
        self.analytics?.configuration.logger.debug(tag: Constants.logTag, log: "POCPlugin is running...")
        return event
    }
}
