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
public protocol Plugin: AnyObject {
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
