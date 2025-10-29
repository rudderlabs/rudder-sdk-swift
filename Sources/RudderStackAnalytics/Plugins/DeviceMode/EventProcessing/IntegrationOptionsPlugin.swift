//
//  IntegrationOptionsPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 23/10/25.
//

import Foundation

/**
 * A plugin to pass or drop events based on the integration options set for a destination in events.
 *
 * The plugin checks if the destination is explicitly enabled or disabled AND
 * if all destinations are enabled or disabled in the event's integrations
 * and then passes or drops the event accordingly.
 *
 * It applies the below logic to decide whether to pass or drop the events:
 *
 * All -> true - Allow
 * All -> false - Block
 *
 * All -> false && key = true - Allow
 * All -> false && key = false - Block
 *
 * key = true - Allow
 * key = false - Block
 *
 * **Note**: Since integrations can be a `[String: AnyCodable]` dictionary, this plugin also handles
 * scenarios where integrations is set to some complex object or non-boolean values.
 */
class IntegrationOptionsPlugin: Plugin {
    
    let destinationKey: String
    
    var pluginType: PluginType = .preProcess
    
    weak var analytics: Analytics?
    
    init(key: String) {
        self.destinationKey = key
    }

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: Event) -> Event? {
        guard let integrations = event.integrations else {
            // No integrations specified - allow event by default
            return event
        }
        
        // First priority: Check for destination-specific boolean flag
        if let destinationValue = integrations[destinationKey]?.value as? Bool {
            return destinationValue ? event : {
                logDroppedEvent(event)
                return nil
            }()
        }
        
        // Second priority: Check for "All" destinations boolean flag
        if let allValue = integrations["All"]?.value as? Bool {
            return allValue ? event : {
                logDroppedEvent(event)
                return nil
            }()
        }
        
        // Default behavior: Allow event if no boolean flags found
        // This handles cases where integrations contain non-boolean values
        return event
    }
    
    /**
     * Logs when an event is dropped due to integration options.
     *
     * - Parameter event: The event that was dropped
     */
    private func logDroppedEvent(_ event: Event) {
        LoggerAnalytics.debug("IntegrationOptionsPlugin: Dropped event \(event) for destination: \(destinationKey)")
    }
}
