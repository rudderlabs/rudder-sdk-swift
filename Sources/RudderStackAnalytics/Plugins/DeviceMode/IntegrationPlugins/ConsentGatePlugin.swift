//
//  ConsentGatePlugin.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Foundation
import Combine

// MARK: - ConsentGatePlugin
/**
 A per-destination plugin that drops events while its destination resolves consent-denied.
 
 The destination's `consentManagement` entries are cached from the source config stream; the consent state is read live on every event so a `setConsent` update applies to the next event immediately. Resolution is fail-open — while consent management is disabled, every event passes.
 */

final class ConsentGatePlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    /// Cached from the source-config stream, asynchronously — `nil` until the first config arrives, which resolves fail-open.
    @Synchronized private(set) var destinationConfig: [String: Any]?
    private let destinationKey: String
    private var cancellables = Set<AnyCancellable>()
    
    /**
     Initializes the ConsentGatePlugin with a destination key.
     
     - Parameter key: The key identifying the destination to gate.
     */
    init(key: String) {
        self.destinationKey = key
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.seedDestinationConfig()
        self.setupConfigurationListener()
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let state = analytics?.consentManagementState.value else { return event }
        
        guard ConsentResolver.resolve(state: state, destinationConfig: destinationConfig) else {
            logger.debug(log: "ConsentGatePlugin: Dropped event for destination: \(destinationKey) — consent denied.")
            return nil
        }
        
        return event
    }
    
    // The chain calls this on removal, which is the deterministic point to drop the source-config
    // subscription — it must not depend on when this plugin happens to be deallocated.
    func teardown() {
        cancellables.removeAll()
    }
}

// MARK: - Private Methods
extension ConsentGatePlugin {
    
    /**
     Sets up a listener for source configuration changes to cache the destination's raw config.
     */
    private func setupConfigurationListener() {
        guard let analytics else { return }
        
        analytics.sourceConfigState.observeDispatched()
            .receive(on: DispatchQueue.global(qos: .default))
            .sink { [weak self] sourceConfig in
                self?.updateDestinationConfig(from: sourceConfig)
            }
            .store(in: &cancellables)
    }
    
    /**
     Reads the config already held in state, synchronously.
     
     The stream above delivers on a background queue, so without this the gate is blind between
     `setup` and the first delivery — and a destination registered after the source config arrived
     is created inside that window, where an unresolvable config fails open.
     */
    private func seedDestinationConfig() {
        guard let analytics else { return }
        self.updateDestinationConfig(from: analytics.sourceConfigState.value)
    }
    
    /// Shared by the seed and the stream, so the two can never disagree on what the cache holds.
    private func updateDestinationConfig(from sourceConfig: SourceConfig) {
        self.destinationConfig = self.findDestination(sourceConfig: sourceConfig, key: self.destinationKey)?
            .destinationConfig.mapValues { $0.value }
    }
    
    /**
     Finds the destination in the source config matching the given key.
     
     - Parameters:
        - sourceConfig: The source configuration containing destinations.
        - key: The destination key to find.
     
     - Returns: The destination if found, nil otherwise.
     */
    private func findDestination(sourceConfig: SourceConfig, key: String) -> Destination? {
        return sourceConfig.source.destinations.first { $0.destinationDefinition.displayName == key }
    }
}
