//
//  ObjCOption.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/05/25.
//

import Foundation

// MARK: - ObjCOptionBuilder
/**
 A builder class for constructing `RudderOption` instances in Objective-C.
 */
@objc(RSOptionBuilder)
public final class ObjCOptionBuilder: NSObject {
    
    private var integrations: [String: Any]?
    private var customContext: [String: Any]?
    private var externalIds: [ExternalId]?

    /**
     Initializes a new builder.
     */
    @objc
    public override init() {
        super.init()
    }

    /**
     Builds and returns the configured `RudderOption` instance.
     */
    @objc
    public func build() -> RudderOption {
        return RudderOption(integrations: integrations, customContext: customContext, externalIds: externalIds)
    }

    /**
     Sets the integrations dictionary.

     - Parameter integrations: A dictionary of integration keys and values.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setIntegrations(_ integrations: [String: Any]?) -> Self {
        self.integrations = integrations?.objCSanitized
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
        self.customContext = customContext?.objCSanitized
        return self
    }

    /**
     Sets the array of external IDs.

     - Parameter externalIds: An array of `ObjCExternalId` objects.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setExternalIds(_ externalIds: [ExternalId]?) -> Self {
        self.externalIds = externalIds
        return self
    }
}
