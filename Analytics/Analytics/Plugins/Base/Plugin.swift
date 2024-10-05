//
//  Plugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - PluginType
@objc
public enum PluginType: Int, CaseIterable {
    case preProcess, onProcess, destination, after, manual
}

// MARK: - Plugin
protocol Plugin: AnyObject {
    var pluginType: PluginType { get set }
    var analytics: AnalyticsClient? { get set }
    
    func setup(analytics: AnalyticsClient)
    func execute(event: Message) -> Message
    
    func teardown()
}

extension Plugin {
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: Message) -> Message{
        return event
    }
    
    func teardown() {}
}

// MARK: - POCPlugin
class POCPlugin: Plugin {
    var analytics: AnalyticsClient?
    
    var pluginType: PluginType = .preProcess
        
    func execute(event: Message) -> Message {
        self.analytics?.configuration.logger.debug(tag: Constants.logTag, log: "POCPlugin is running...")
        if let json = event.toJSONString {
            self.analytics?.configuration.storage?.write(message: json)
        }
        return event
    }
}
