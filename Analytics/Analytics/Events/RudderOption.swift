//
//  MessageOptions.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/11/24.
//

import Foundation

// MARK: - RudderOptionType

/**
 A base protocol for managing Rudder options.

 The `RudderOptionType` protocol defines methods and properties for managing options like integrations, custom context and externalIds that can be added to event messages. Conforming types are expected to implement the logic for adding these options.

 - Properties:
    - `integrations`: A dictionary of integrations and their enabled/disabled state.
    - `customContext`: A dictionary of custom context values associated with the event.
    - `externalIds`: An array of external IDs to be included with the event message.
 */
protocol RudderOptionType {
    
    /**
     This property manages the integrations to be included with the event message.
     */
    var integrations: [String: Any]? { get }

    /**
     This context can include additional metadata, such as user information or device details.
     */
    var customContext: [String: Any]? { get }
    
    /**
     This property holds the external IDs to be included with the event message.
     */
    var externalIds: [ExternalId]? { get }
}

// MARK: - RudderOption

/**
 A class that implements the `RudderOptionType` protocol for managing Rudder options.

 The `RudderOption` class allows adding and updating integration settings and custom context data for event messages.
 This class is useful for customizing the event payload with additional metadata or toggling integrations on or off.

 - Properties:
    - `integrations`: A dictionary of integrations and their enabled/disabled state.
    - `customContext`: A dictionary of custom context values associated with the event.
    - `externalIds`: An array of external IDs associated with the event.
 */
public class RudderOption: RudderOptionType {
    
    /// A dictionary of integration names as keys and their enabled state as boolean values.
    private(set) public var integrations: [String: Any]?
    
    /// A dictionary of custom context values associated with the event message.
    private(set) public var customContext: [String: Any]?
    
    /// An array of external IDs associated with the event message.
    private(set) public var externalIds: [ExternalId]?
    
    /**
     Initializes a new instance of `RudderOption`.

     The initial integrations are set to the default integrations defined in `Constants.Payload.integration`.
     */
    
    public init(integrations: [String: Any]? = nil, customContext: [String: Any]? = nil, externalIds: [ExternalId]? = nil) {
        self.integrations = integrations ?? Constants.Payload.integration
        self.customContext = customContext
        self.externalIds = externalIds
    }
}
