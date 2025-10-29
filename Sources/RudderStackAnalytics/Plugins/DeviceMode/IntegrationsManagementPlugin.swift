//
//  IntegrationsManagementPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation
import Combine

// MARK: - IntegrationsManagementPlugin
/**
 This plugin is responsible for fetching the source configuration and queuing events until the configuration is retrieved.
 It also replays the queued events once the source configuration has been successfully fetched.
 */
class IntegrationsManagementPlugin: Plugin {
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    private var cancellables = Set<AnyCancellable>()
    private var processingTask: Task<Void, Never>?
    private let processingQueue = DispatchQueue(label: "IntegrationsManagement", qos: .default)
    
    private let queuedEventsChannel: AsyncChannel<Event> = AsyncChannel(bufferingPolicy: .bufferingNewest(IntegrationsManagementConstants.maxQueueSize))
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    
        // observing the sourceConfig
        var configIndex = 0
        self.analytics?.sourceConfigState.state
            .dropFirst()
            .removeDuplicates { (previous: SourceConfig, current: SourceConfig) -> Bool in
                previous.source.updatedAt == current.source.updatedAt
            }
            .receive(on: processingQueue)
            .sink { [weak self] sourceConfig in
                guard let self, sourceConfig.source.isSourceEnabled else { return }
                
                self.integrationPluginChain?.apply { plugin in
                    if let integrationPlugin = plugin as? IntegrationPlugin {
                        self.initDestination(sourceConfig: sourceConfig, integration: integrationPlugin)
                    }
                }
                
                // Start processing queued events when SourceConfig is fetched for the first time
                if configIndex == IntegrationsManagementConstants.firstIndex {
                    self.setIsSourceEnabledFetchedAtLeastOnce(true)
                    self.processEvents()
                }
                configIndex += 1
            }
            .store(in: &cancellables)
    }
    
    func intercept(event: any Event) -> (any Event)? {
        LoggerAnalytics.debug("IntegrationsManagementPlugin: queueing event")
        
        do {
            try queuedEventsChannel.send(event)
        } catch {
            // Channel is closed or other error, return event as-is
            LoggerAnalytics.error("IntegrationsManagementPlugin: Failed to queue event: \(error)")
        }
        
        return event
    }
    
    private func processEvents() {
        LoggerAnalytics.debug("IntegrationsManagementPlugin: Starting to process queued events")
        
        processingTask = Task { [weak self] in
            guard let channel = self?.queuedEventsChannel else { return }

            for await event in channel.receive() {
                if Task.isCancelled { break }
                
                guard let self else { break }
                self.integrationPluginChain?.process(event: event)
            }
        }
    }
    
    deinit {
        self.queuedEventsChannel.close()
        processingTask?.cancel()
        processingTask = nil
        self.cancellables.removeAll()
    }
}

extension IntegrationsManagementPlugin {
    var integrationPluginStores: [String: IntegrationPluginStore]? {
        return self.analytics?.integrationsController?.integrationPluginStores
    }
    
    var integrationPluginChain: PluginChain? {
        return self.analytics?.integrationsController?.integrationPluginChain
    }
    
    func setIsSourceEnabledFetchedAtLeastOnce(_ value: Bool) {
        self.analytics?.integrationsController?.isSourceEnabledFetchedAtLeastOnce = value
    }
    
    func initDestination(sourceConfig: SourceConfig, integration: IntegrationPlugin) {
        self.analytics?.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: integration)
    }
}

// MARK: - IntegrationsManagementConstants

struct IntegrationsManagementConstants {
    static let maxQueueSize = 1000
    static let firstIndex = 0
}
