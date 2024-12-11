//
//  Plugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - PluginType
@objc
enum PluginType: Int, CaseIterable {
    case preProcess, onProcess, destination, after, manual
}

// MARK: - Plugin
protocol Plugin: AnyObject {
    var pluginType: PluginType { get set }
    var analytics: AnalyticsClient? { get set }
    
    func setup(analytics: AnalyticsClient)
    func execute(event: Message) -> Message?
    
    func teardown()
}

extension Plugin {
    func setup(analytics: AnalyticsClient) { self.analytics = analytics }
    func execute(event: Message) -> Message? { event }
    func teardown() {}
}

// MARK: - MessagePlugin
protocol MessagePlugin: Plugin {
    func track(payload: TrackEvent) -> Message?
    func screen(payload: ScreenEvent) -> Message?
    func group(payload: GroupEvent) -> Message?
    func flush(payload: FlushEvent) -> Message?
}

extension MessagePlugin {
    func track(payload: TrackEvent) -> Message? { payload }
    func screen(payload: TrackEvent) -> Message? { payload }
    func group(payload: TrackEvent) -> Message? { payload }
    func flush(payload: TrackEvent) -> Message? { payload }
    
    func execute(event: any Message) -> (any Message)? {
        return switch event {
        case let event as TrackEvent: self.track(payload: event)
        case let event as ScreenEvent: self.screen(payload: event)
        case let event as GroupEvent: self.group(payload: event)
        case let event as FlushEvent: self.flush(payload: event)
        default : nil
        }
    }
}

// MARK: - ContextInfoPlugin
protocol ContextInfoPlugin: Plugin {
    func append(info: [String: Any], to message: Message) -> Message
}

extension ContextInfoPlugin {
    func append(info: [String: Any], to event: Message) -> Message {
        var message = event
        var context = event.context ?? [:]
        
        context = context + info.mapValues { AnyCodable($0) }
        message.context = context
        return message
    }
}

// MARK: - POCPlugin
// TODO: This is a sample plugin and will be removed in future..
class POCPlugin: Plugin {
    var analytics: AnalyticsClient?
    
    var pluginType: PluginType = .preProcess
    
    func execute(event: Message) -> Message? {
        self.analytics?.configuration.logger.debug(tag: Constants.logTag, log: "POCPlugin is running...")
        return event
    }
}
