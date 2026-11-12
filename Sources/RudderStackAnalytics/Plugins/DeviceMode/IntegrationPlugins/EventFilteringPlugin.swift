//
//  EventFilteringPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 21/10/25.
//

import Foundation
import Combine

struct EventFilteringPluginConstants {
    static let allowListEventsKey = "whitelistedEvents"
    static let denyListEventsKey = "blacklistedEvents"
    static let eventFilteringOptionKey = "eventFilteringOption"
    static let eventNameKey = "eventName"
}

// MARK: - EventFilteringPlugin
/**
 A plugin to filter events based on the event filtering option provided in the destination config.
 
 This plugin filters the events based on the event filtering option provided in the destination config.
 The plugin supports two types of event filtering options based on the dashboard configuration:
 1. Allow list events: Only the events present in the allow list will be allowed.
 2. Deny list events: All the events except the ones present in the deny list will be allowed.
 */
final class EventFilteringPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    private let destinationKey: String
    /// `nil` until the first configuration arrives, so an invalid first list still gives the result it always gave.
    @Synchronized private var filteringRule: FilteringRule?
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
            logger.debug(log: "EventFilteringPlugin: Dropped event '\(eventName)' for destination: \(destinationKey)")
            return nil
        }
        
        return event
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - FilteringRule
extension EventFilteringPlugin {

    /** The filtering option and its event names, which an update replaces together. */
    private struct FilteringRule {
        let option: String
        let events: Set<String>

        static let none = FilteringRule(option: "", events: [])
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
        guard let rule = filteringRule else { return false }
        switch rule.option {
        case EventFilteringPluginConstants.allowListEventsKey:
            return !rule.events.contains(eventName)
        case EventFilteringPluginConstants.denyListEventsKey:
            return rule.events.contains(eventName)
        default:
            return false
        }
    }
    
    /**
     Sets up a listener for source configuration changes to update filtering configuration.
     */
    private func setupConfigurationListener() {
        guard let analytics else { return }
        
        // `observeDispatched()` skips the initial empty state without depending on when this plugin
        // subscribes. An integration can be added long after the source config has been dispatched,
        // in which case the current config is delivered immediately on subscription.
        analytics.sourceConfigState.observeDispatched()
            .receive(on: DispatchQueue.global(qos: .default))
            .sink { [weak self] sourceConfig in
                guard let self = self, sourceConfig.source.isSourceEnabled else { return }
                
                // Find the destination configuration for this plugin
                if let destination = self.findDestination(sourceConfig: sourceConfig, key: self.destinationKey) {
                    logger.debug(log: "EventFilteringPlugin: Updating configuration for destination: \(self.destinationKey)")
                    // Convert AnyCodable values to regular dictionary
                    let configDict = destination.destinationConfig.mapValues { $0.value }
                    self.updateFilteringConfiguration(destinationConfig: configDict)
                } else {
                    logger.debug(log: "EventFilteringPlugin: No configuration found for destination: \(self.destinationKey), clearing filters")
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
            logger.debug(log: "EventFilteringPlugin: No destination config found for: \(destinationKey)")
            filteringRule = FilteringRule.none
            return
        }
        
        let newFilteringOption = destinationConfig[EventFilteringPluginConstants.eventFilteringOptionKey] as? String ?? ""
        
        if newFilteringOption.isEmpty {
            logger.debug(log: "EventFilteringPlugin: Missing event filtering option for destination: \(destinationKey)")
            filteringRule = FilteringRule.none
            return
        }

        // A malformed list keeps the last valid rule.
        if !hasValidFilteringArray(filteringOption: newFilteringOption, destinationConfig: destinationConfig) {
            guard filteringRule == nil else {
                logger.debug(log: "EventFilteringPlugin: Malformed configuration detected for destination: \(destinationKey), keeping the previous filtering rule")
                return
            }
            logger.debug(log: "EventFilteringPlugin: Malformed configuration detected for destination: \(destinationKey), applying its valid entries")
            filteringRule = firstRuleFromInvalidList(filteringOption: newFilteringOption, destinationConfig: destinationConfig)
            return
        }

        let events = getEventFilteringList(eventFilteringOption: newFilteringOption, destinationConfig: destinationConfig)
        filteringRule = FilteringRule(option: newFilteringOption, events: Set(events))
    }
    
    /**
     Checks if the destination configuration has a valid filtering array structure.
     
     - Parameters:
        - filteringOption: The filtering option to check.
        - destinationConfig: The destination configuration dictionary.
     - Returns: `true` if the option needs no list, or if every entry of its list has a string event name; `false` otherwise.
     */
    private func hasValidFilteringArray(filteringOption: String, destinationConfig: [String: Any]) -> Bool {
        let listKey: String
        switch filteringOption {
        case EventFilteringPluginConstants.allowListEventsKey:
            listKey = EventFilteringPluginConstants.allowListEventsKey
        case EventFilteringPluginConstants.denyListEventsKey:
            listKey = EventFilteringPluginConstants.denyListEventsKey
        default:
            return true
        }
        
        guard let entries = destinationConfig[listKey] as? [[String: Any]] else { return false }
        // One invalid entry rejects the whole list, so a partly read list never replaces a valid rule.
        // The config decoder turns some strings into a URL or a Date; each was still a string in the JSON.
        return entries.allSatisfy { entry in
            let eventName = entry[EventFilteringPluginConstants.eventNameKey]
            return eventName is String || eventName is URL || eventName is Date
        }
    }

    /**
     The rule for an invalid list in the first configuration: its valid event names, or no filter when the list is
     not an array. This is the result the plugin gave before it kept the last valid rule.
     */
    private func firstRuleFromInvalidList(filteringOption: String, destinationConfig: [String: Any]) -> FilteringRule {
        guard destinationConfig[filteringOption] is [[String: Any]] else { return .none }
        let events = getEventFilteringList(eventFilteringOption: filteringOption, destinationConfig: destinationConfig)
        return FilteringRule(option: filteringOption, events: Set(events))
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
        case EventFilteringPluginConstants.allowListEventsKey:
            listKey = EventFilteringPluginConstants.allowListEventsKey
        case EventFilteringPluginConstants.denyListEventsKey:
            listKey = EventFilteringPluginConstants.denyListEventsKey
        default:
            return []
        }
        
        guard let eventsArray = destinationConfig[listKey] as? [[String: Any]] else {
            logger.error(log: "EventFilteringPlugin: Missing \(listKey) in destination config for: \(destinationKey)", error: nil)
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
            guard let eventName = eventDict[EventFilteringPluginConstants.eventNameKey] as? String else {
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

// MARK: - Testing Interface
extension EventFilteringPlugin {
    
    /**
     Updates the plugin configuration with new destination config.
     This method is primarily intended for testing purposes to simulate configuration changes.
     In production, configuration updates are handled automatically through the source configuration listener.
     
     - Parameter destinationConfig: The new destination configuration.
     */
    func updateConfiguration(destinationConfig: [String: Any]?) {
        updateFilteringConfiguration(destinationConfig: destinationConfig)
    }
}
