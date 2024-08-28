//
//  AnalyticsClient.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/08/24.
//

import Foundation

// MARK: - Analytics
/**
 This class serves as the main interface to the SDK, allowing user interaction.
 */
@objcMembers
public class Analytics {
    public var configuration: Configuration
    
    private var pluginChain: PluginChain!
    private let analyticsQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        return queue
    }()
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.setup()
    }
    
    // MARK: - Track Event
    public func track(name: String, properties: RudderProperties = RudderProperties(), options: RudderOptions = RudderOptions()) {
        let event = TrackEvent(event: name, properties: properties, options: options)
        self.process(event: event)
    }
}

// MARK: - Private functions
extension Analytics {
    private func setup() {
        self.pluginChain = PluginChain(analytics: self)
        self.pluginChain.add(plugin: POCPlugin())
    }
    
    private func process(event: MessageEvent) {
        self.analyticsQueue.addOperation {
            self.pluginChain.process(event: event)
        }
    }
}

