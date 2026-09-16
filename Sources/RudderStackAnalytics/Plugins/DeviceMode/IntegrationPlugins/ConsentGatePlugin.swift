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

        // An event must be consented twice: under the decision in force now, and under the one it
        // was created with. A grant never reaches backwards to authorise data the user had refused;
        // a revoke still stops delivery of everything already in flight.
        let allowedNow = ConsentResolver.resolve(state: state, destinationConfig: destinationConfig)
        let allowedWhenCreated = self.capturedConsent(of: event)
            .map { ConsentResolver.resolve(state: $0, destinationConfig: destinationConfig) } ?? true
        
        guard allowedNow, allowedWhenCreated else {
            logger.debug(log: "ConsentGatePlugin: Dropped event for destination: \(destinationKey) — consent denied.")
            return nil
        }
        
        return event
    }

    /**
     The consent the event was created under, or `nil` when it carries none.

     An event that never passed through `Analytics.process` records no decision, so it is gated on
     the live state alone — the same fail-open posture the resolver takes for missing configuration.
     */
    private func capturedConsent(of event: any Event) -> ConsentManagement? {
        guard let stamp = (event as? ReservedContextCapturing)?
            .capturedReservedContext?[ConsentManagement.contextKey] as? [String: Any] else { return nil }
        
        return ConsentManagement.from(contextStamp: stamp)
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
        // Read as the initialization gate reads it, so both resolve the same consent IDs.
        self.destinationConfig = self.findDestination(sourceConfig: sourceConfig, key: self.destinationKey)?
            .destinationConfig.rawDictionary
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
