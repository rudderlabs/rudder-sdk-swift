//
//  EventFilteringPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 21/10/25.
//

import Foundation
import Combine

// MARK: - Constants
private let whiteListEventsKey = "whitelistedEvents"
private let blackListEventsKey = "blacklistedEvents"
private let eventFilteringOptionKey = "eventFilteringOption"

// MARK: - EventFilteringPlugin
/**
 A plugin to filter events based on the event filtering option provided in the destination config.
 
 This plugin filters the events based on the event filtering option provided in the destination config.
 The plugin supports two types of event filtering options based on the dashboard configuration:
 1. Whitelist events: Only the events present in the whitelist will be allowed.
 2. Blacklist events: All the events except the ones present in the blacklist will be allowed.
 */
final class EventFilteringPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    private let destinationKey: String
    @Synchronized private var filteringOption: String = ""
    @Synchronized private var filteringList: [String] = []
    private var cancellables = Set<AnyCancellable>()
    
    /**
     Initializes the EventFilteringPlugin with a destination key.
     
     - Parameter key: The key identifying the destination for which events should be filtered.
     */
    init(key: String) {
        self.destinationKey = key
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        setupConfigurationListener()
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let trackEvent = event as? TrackEvent else {
            return event
        }
        
        let eventName = trackEvent.event.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if shouldDropEvent(eventName: eventName) {
            LoggerAnalytics.debug("EventFilteringPlugin: Dropped event '\(eventName)' for destination: \(destinationKey)")
            return nil
        }
        
        return event
    }
    
    deinit {
        filteringList.removeAll()
        filteringOption = ""
        cancellables.removeAll()
    }
}

// MARK: - Private Methods
extension EventFilteringPlugin {
    
    /**
     Determines whether an event should be dropped based on the current filtering configuration.
     
     - Parameter eventName: The name of the event to evaluate.
     - Returns: `true` if the event should be dropped, `false` otherwise.
     */
    private func shouldDropEvent(eventName: String) -> Bool {
        switch filteringOption {
        case whiteListEventsKey:
            return !filteringList.contains(eventName)
        case blackListEventsKey:
            return filteringList.contains(eventName)
        default:
            return false
        }
    }
    
    /**
     Sets up a listener for source configuration changes to update filtering configuration.
     */
    private func setupConfigurationListener() {
        guard let analytics = analytics else {
            LoggerAnalytics.error("EventFilteringPlugin: Analytics instance not available for destination: \(destinationKey)")
            return
        }
        
        analytics.sourceConfigState.state
            .dropFirst() // Skip the initial empty state
            .removeDuplicates { (previous: SourceConfig, current: SourceConfig) -> Bool in
                previous.source.updatedAt == current.source.updatedAt
            }
            .receive(on: DispatchQueue.global(qos: .default))
            .sink { [weak self] sourceConfig in
                guard let self = self, sourceConfig.source.isSourceEnabled else { return }
                
                // Find the destination configuration for this plugin
                if let destination = self.findDestination(sourceConfig: sourceConfig, key: self.destinationKey) {
                    LoggerAnalytics.debug("EventFilteringPlugin: Updating configuration for destination: \(self.destinationKey)")
                    // Convert AnyCodable values to regular dictionary
                    let configDict = destination.destinationConfig.mapValues { $0.value }
                    self.updateFilteringConfiguration(destinationConfig: configDict)
                } else {
                    LoggerAnalytics.debug("EventFilteringPlugin: No configuration found for destination: \(self.destinationKey), clearing filters")
                    self.updateFilteringConfiguration(destinationConfig: nil)
                }
            }
            .store(in: &cancellables)
    }
    
    /**
     Updates the filtering configuration based on the destination configuration.
     
     - Parameter destinationConfig: The destination configuration dictionary.
     */
    private func updateFilteringConfiguration(destinationConfig: [String: Any]?) {
        guard let destinationConfig = destinationConfig else {
            LoggerAnalytics.debug("EventFilteringPlugin: No destination config found for: \(destinationKey)")
            return
        }
        
        let newFilteringOption = destinationConfig[eventFilteringOptionKey] as? String ?? ""
        
        if newFilteringOption.isEmpty {
            LoggerAnalytics.debug("EventFilteringPlugin: Missing event filtering option for destination: \(destinationKey)")
            filteringOption = ""
            filteringList.removeAll()
            return
        }
        
        // Check if the configuration has a valid structure
        if !hasValidFilteringArray(filteringOption: newFilteringOption, destinationConfig: destinationConfig) {
            LoggerAnalytics.debug("EventFilteringPlugin: Malformed configuration detected for destination: \(destinationKey), disabling filtering")
            filteringOption = ""
            filteringList.removeAll()
            return
        }
        
        filteringOption = newFilteringOption
        filteringList = getEventFilteringList(eventFilteringOption: filteringOption, destinationConfig: destinationConfig)
    }
    
    /**
     Checks if the destination configuration has a valid filtering array structure.
     
     - Parameters:
        - filteringOption: The filtering option to check.
        - destinationConfig: The destination configuration dictionary.
     - Returns: `true` if the configuration has a valid array structure, `false` otherwise.
     */
    private func hasValidFilteringArray(filteringOption: String, destinationConfig: [String: Any]) -> Bool {
        let listKey: String
        switch filteringOption {
        case whiteListEventsKey:
            listKey = whiteListEventsKey
        case blackListEventsKey:
            listKey = blackListEventsKey
        default:
            return false
        }
        
        return destinationConfig[listKey] is [[String: Any]]
    }
    
    /**
     Retrieves the list of events to be filtered based on the filtering option.
     
     - Parameters:
     - eventFilteringOption: The filtering option ("whitelistedEvents" or "blacklistedEvents").
     - destinationConfig: The destination configuration dictionary.
     - Returns: An array of event names to be filtered.
     */
    private func getEventFilteringList(eventFilteringOption: String, destinationConfig: [String: Any]) -> [String] {
        let listKey: String
        switch eventFilteringOption {
        case whiteListEventsKey:
            listKey = whiteListEventsKey
        case blackListEventsKey:
            listKey = blackListEventsKey
        default:
            return []
        }
        
        guard let eventsArray = destinationConfig[listKey] as? [[String: Any]] else {
            LoggerAnalytics.error("EventFilteringPlugin: Missing \(listKey) in destination config for: \(destinationKey)")
            return []
        }
        
        return parseFilteredEvents(eventsArray: eventsArray)
    }
    
    /**
     Parses the filtered events array to extract event names.
     
     - Parameter eventsArray: The array of event dictionaries from the configuration.
     - Returns: An array of event names.
     */
    private func parseFilteredEvents(eventsArray: [[String: Any]]) -> [String] {
        return eventsArray.compactMap { eventDict in
            guard let eventName = eventDict["eventName"] as? String else {
                return nil
            }
            let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedName.isEmpty ? nil : trimmedName
        }
    }
    
    /**
     Finds a destination in the source configuration by key.
     
     - Parameters:
        - sourceConfig: The source configuration containing destinations.
        - key: The destination key to find.
     - Returns: The destination if found, nil otherwise.
     */
    private func findDestination(sourceConfig: SourceConfig, key: String) -> Destination? {
        return sourceConfig.source.destinations.first { $0.destinationDefinition.displayName == key }
    }
}

// MARK: - Configuration Update Interface
extension EventFilteringPlugin {
    
    /**
     Updates the plugin configuration with new destination config.
     This method will be called by the IntegrationsManagementPlugin when configuration changes.
     
     - Parameter destinationConfig: The new destination configuration.
     */
    func updateConfiguration(destinationConfig: [String: Any]?) {
        updateFilteringConfiguration(destinationConfig: destinationConfig)
    }
}
