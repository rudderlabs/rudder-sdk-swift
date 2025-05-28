//
//  ObjCOption.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/05/25.
//

import Foundation

// MARK: - ObjCOption
/**
 A wrapper class that exposes the Swift `RudderOption` to Objective-C.
 */
@objc(RSOption)
public final class ObjCOption: NSObject {
    
    let option: RudderOption

    /** A dictionary to configure integrations, merged with default payload integration settings. */
    @objc internal(set) public var integrations: [String: Any]? {
        get { option.integrations }
        set { option.integrations = (newValue ?? [:]) + Constants.payload.integration }
    }

    /** A dictionary for custom contextual data. */
    @objc internal(set) public var customContext: [String: Any]? {
        get { option.customContext }
        set { option.customContext = newValue }
    }

    /** An array of external IDs associated with the event. */
    @objc internal(set) public var externalIds: [ObjCExternalId]? {
        get { option.externalIds?.compactMap { ObjCExternalId(externalId: $0) } }
        set { option.externalIds = newValue?.map { $0.externalId } }
    }

    /**
     Initializes a new `ObjCOption` instance with default settings.
     */
    override init() {
        self.option = RudderOption()
        super.init()
    }
}

// MARK: - ObjCOptionBuilder
/**
 A builder class for constructing `ObjCOption` instances in Objective-C.
 */
@objc(RSOptionBuilder)
public final class ObjCOptionBuilder: NSObject {
    
    let option: ObjCOption

    /**
     Initializes a new builder with a default `ObjCOption` instance.
     */
    @objc
    public override init() {
        self.option = ObjCOption()
        super.init()
    }

    /**
     Builds and returns the configured `ObjCOption` instance.
     */
    @objc
    public func build() -> ObjCOption {
        return option
    }

    /**
     Sets the integrations dictionary.

     - Parameter integrations: A dictionary of integration keys and values.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setIntegrations(_ integrations: [String: Any]?) -> Self {
        self.option.integrations = integrations?.objCSanitized
        return self
    }

    /**
     Sets the custom context dictionary.

     - Parameter customContext: A dictionary of custom context data.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setCustomContext(_ customContext: [String: Any]?) -> Self {
        self.option.customContext = customContext?.objCSanitized
        return self
    }

    /**
     Sets the array of external IDs.

     - Parameter externalIds: An array of `ObjCExternalId` objects.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setExternalIds(_ externalIds: [ObjCExternalId]?) -> Self {
        self.option.externalIds = externalIds
        return self
    }
}

// MARK: - ObjCExternalId
/**
 A wrapper for representing an external ID in Objective-C.
 */
@objc(RSExternalId)
public final class ObjCExternalId: NSObject {
    
    let externalId: ExternalId

    /**
     Initializes a new external ID with the specified type and ID.

     - Parameters:
       - type: The type of the external ID.
       - id: The external identifier string.
     */
    @objc
    public init(type: String, id: String) {
        self.externalId = ExternalId(type: type, id: id)
        super.init()
    }

    /**
     Initializes the wrapper using an existing `ExternalId` instance.

     - Parameter externalId: The existing `ExternalId` to wrap.
     */
    public init(externalId: ExternalId) {
        self.externalId = externalId
        super.init()
    }
}
