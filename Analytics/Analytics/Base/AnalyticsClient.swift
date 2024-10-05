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
public class AnalyticsClient {
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
    public func track(name: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        let event = TrackEvent(event: name, properties: CodableDictionary(properties), options: CodableDictionary(options))
        self.process(event: event)
    }
}

// MARK: - Private functions
extension AnalyticsClient {
    private func setup() {
        self.pluginChain = PluginChain(analytics: self)
        self.pluginChain.add(plugin: POCPlugin())
        
        self.analyticsQueue.addOperation {
            self.collectConfiguration()
        }
    }
    
    private func process(event: Message) {
        self.analyticsQueue.addOperation {
            self.pluginChain.process(event: event)
        }
    }
}

// MARK: - Backend Configuration
extension AnalyticsClient {
    private func collectConfiguration() {
        let client = HttpClient(analytics: self)
        client.getConfiguarationData()
    }
}
