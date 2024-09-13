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
    case preProcess, onProcess, integrations, utility
}

// MARK: - Plugin
protocol Plugin: AnyObject {
    var pluginType: PluginType { get set }
    var analytics: AnalyticsClient? { get set }
    
    func setup(analytics: AnalyticsClient)
    func execute(event: MessageEvent) -> MessageEvent
    
    func teardown()
}

extension Plugin {
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: MessageEvent) -> MessageEvent{
        return event
    }
    
    func teardown() {}
}

// MARK: - POCPlugin
class POCPlugin: Plugin {
    var analytics: AnalyticsClient?
    
    var pluginType: PluginType = .preProcess
        
    func execute(event: MessageEvent) -> MessageEvent {
        self.analytics?.configuration.logger.debug(tag: Constants.logTag, log: "POCPlugin is running...")
        if let json = convertToJSONString(event) {
            self.analytics?.configuration.storage?.write(value: json, key: .event)
        }
        return event
    }
    
    func convertToJSONString<T: Codable>(_ object: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Optional: for pretty-printed JSON
        
        do {
            let jsonData = try encoder.encode(object)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch {
            print("Error encoding object to JSON: \(error)")
            return nil
        }
    }
}
