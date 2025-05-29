//
//  RudderOption.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/11/24.
//

import Foundation

// MARK: - RudderOption

/**
 A class that allows adding and updating integration settings and custom context data for event payload.

 This class is useful for customizing the event payload with additional metadata or toggling integrations on or off.

 - Properties:
    - `integrations`: A dictionary of integrations and their enabled/disabled state details.
    - `customContext`: A dictionary of custom context values associated with the event.
    - `externalIds`: An array of external IDs associated with the event.
 */

@objc(RSOption)
public class RudderOption: NSObject {
    
    /// A dictionary of integration names as keys and their state values.
    @objc internal(set) public var integrations: [String: Any]?
    
    /// A dictionary of custom context values associated with the event payload.
    @objc internal(set) public var customContext: [String: Any]?
    
    /// An array of external IDs associated with the event payload.
    @objc internal(set) public var externalIds: [ExternalId]?
    
    /**
     Initializes a new instance of `RudderOption`.

     The initial integrations are set to the default integrations defined in `Constants.payload.integration`.
     */
    @objc
    public init(integrations: [String: Any]? = nil, customContext: [String: Any]? = nil, externalIds: [ExternalId]? = nil) {
        self.integrations = (integrations ?? [:]) + Constants.payload.integration
        self.customContext = customContext
        self.externalIds = externalIds
    }
}

// MARK: - ExternalId
/**
 A struct representing an external identifier associated with the user.
 
 - Properties:
 - `type`: The type of the external identifier
 - `id`: The value of the external identifier.
 
 - Conformance:
 - `Codable`: Allows the `ExternalId` to be encoded and decoded using `JSONEncoder` and `JSONDecoder`.
 */
@objc(RSExternalId)
public class ExternalId: NSObject, Codable {
    /// The type of the external identifier.
    private(set) public var type: String
    
    /// The value of the external identifier.
    private(set) public var id: String
    
    /**
     Initializes a new instance of `ExternalId` with the given `type` and `id`.
     
     - Parameters:
        - type: The type of the external identifier (e.g., "google", "facebook").
        - id: The value of the external identifier (e.g., "user_12345").
     
     - Returns: A new `ExternalId` instance.
     */
    @objc
    public init(type: String, id: String) {
        self.type = type
        self.id = id
    }
}
