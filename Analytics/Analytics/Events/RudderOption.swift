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

 - Methods:
    - `addIntegration(_:isEnabled:)`: Adds or updates an integration's enabled state.
    - `addCustomContext(_:key:)`: Adds a custom context value for a specific key.
    - `addExternalId(_:)`: Adds an external ID to the list of external IDs.
 */
protocol RudderOptionType {
    
    /**
     This property manages the integrations to be included with the event message.
     */
    var integrations: [String: Bool]? { get }

    /**
     This context can include additional metadata, such as user information or device details.
     */
    var customContext: [String: Any]? { get }
    
    /**
     This property holds the external IDs to be included with the event message.
     */
    var externalIds: [ExternalId]? { get }

    /**
     Adds or updates an integration's enabled state.

     - Parameter integration: The name of the integration to add or update.
     - Parameter isEnabled: A boolean value indicating whether the integration is enabled or disabled.
     - Returns: The current instance of `RudderOptionType`.
     */
    func addIntegration(_ integration: String, isEnabled: Bool) -> Self
    
    /**
     Adds custom context data associated with the event.

     - Parameter context: The context data to associate with the event.
     - Parameter key: The key under which the context data should be stored.
     - Returns: The current instance of `RudderOptionType`.
     */
    func addCustomContext(_ context: Any, key: String) -> Self
    
    /**
     Adds an external ID to the list of external IDs.

     - Parameter id: The external ID to add.
     - Returns: The current instance of `RudderOptionType`.
     */
    func addExternalId(_ id: ExternalId) -> Self
}

extension RudderOptionType {

    /**
     Adds a set of integrations to the `integrations` property.

     - Parameter integrations: A reference to the `integrations` dictionary that will be modified.
     - Parameter values: A dictionary of integration names and their enabled states.
     */
    func addIntegration(_ integrations: inout [String: Bool]?, values: [String: Bool]) {
        if integrations == nil { integrations = Constants.Payload.integration }
        integrations?.merge(values, uniquingKeysWith: { $1 })
    }
    
    /**
     Adds a set of custom context data to the `customContext` property.

     - Parameter context: A reference to the `customContext` dictionary that will be modified.
     - Parameter values: A dictionary of context data to be merged into the existing context.
     */
    func addCustomContext(_ context: inout [String: Any]?, values: [String: Any]) {
        if context == nil { context = [:] }
        context?.merge(values, uniquingKeysWith: { $1 })
    }
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

 - Methods:
    - `addIntegration(_:isEnabled:)`: Adds or updates an integration's enabled state.
    - `addCustomContext(_:key:)`: Adds custom context data for a specific key.
    - `addExternalId(_:)`: Adds an external ID to the list of external IDs.
 */
public class RudderOption: RudderOptionType {
    
    /// A dictionary of integration names as keys and their enabled state as boolean values.
    internal(set) public var integrations: [String: Bool]?
    
    /// A dictionary of custom context values associated with the event message.
    private(set) public var customContext: [String: Any]?
    
    /// An array of external IDs associated with the event message.
    private(set) public var externalIds: [ExternalId]?
    
    /**
     Initializes a new instance of `RudderOption`.

     The initial integrations are set to the default integrations defined in `Constants.Payload.integration`.
     */
    public init() {
        self.integrations = Constants.Payload.integration
    }

    /**
     Adds or updates an integration's enabled state.

     - Parameter integration: The name of the integration to add or update.
     - Parameter isEnabled: A boolean value indicating whether the integration is enabled or disabled.
     - Returns: The current instance of `RudderOption`.
     */
    @discardableResult
    public func addIntegration(_ integration: String, isEnabled: Bool) -> Self {
        self.addIntegration(&self.integrations, values: [integration: isEnabled])
        return self
    }

    /**
     Adds custom context data for a specific key.

     - Parameter context: The context data to associate with the event.
     - Parameter key: The key under which the context data should be stored.
     - Returns: The current instance of `RudderOption`.
     */
    @discardableResult
    public func addCustomContext(_ context: Any, key: String) -> Self {
        self.addCustomContext(&self.customContext, values: [key: context])
        return self
    }
    
    /**
     Adds an external ID to the list of external IDs.

     - Parameter id: The external ID to add.
     - Returns: The current instance of `RudderOption`.
     */
    @discardableResult
    public func addExternalId(_ id: ExternalId) -> Self {
        if self.externalIds == nil { self.externalIds = [] }
        self.externalIds?.append(id)
        return self
    }
}
