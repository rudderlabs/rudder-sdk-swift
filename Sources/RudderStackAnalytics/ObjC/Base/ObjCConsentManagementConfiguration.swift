//
//  ObjCConsentManagementConfiguration.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Foundation

// MARK: - ObjCConsentConfigurationBuilder
/**
 A builder class for constructing `ConsentManagementConfiguration` instances for Objective-C usage.
 */

@objc(RSSConsentConfigurationBuilder)
public final class ObjCConsentConfigurationBuilder: NSObject {
    private var enabled: Bool = Constants.defaultConfig.consentManagementEnabled
    private var provider: ConsentManagementProvider = .custom
    private var allowedConsentIds: [String] = []
    private var deniedConsentIds: [String] = []
    
    /**
     Initializes a new builder.
     */
    @objc
    public override init() {
        super.init()
    }
    
    /**
     Builds and returns the configured `ConsentManagementConfiguration` instance.
     */
    @objc
    public func build() -> ConsentManagementConfiguration {
        return ConsentManagementConfiguration(enabled: enabled, provider: provider, allowedConsentIds: allowedConsentIds, deniedConsentIds: deniedConsentIds)
    }
    
    /**
     Sets whether consent management is enabled.
     
     - Parameter enabled: A Boolean indicating whether consent management should be enabled.
     */
    @objc
    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Self {
        self.enabled = enabled
        return self
    }
    
    /**
     Sets the consent provider.
     
     - Parameter provider: The consent provider to use. Currently only `custom` is supported.
     */
    @objc
    @discardableResult
    public func setProvider(_ provider: ConsentManagementProvider) -> Self {
        self.provider = provider
        return self
    }
    
    /**
     Sets the consent category IDs the user has granted.
     
     - Parameter allowedIds: The granted consent category IDs.
     */
    @objc
    @discardableResult
    public func setAllowedConsentIds(_ allowedIds: [String]) -> Self {
        self.allowedConsentIds = allowedIds
        return self
    }
    
    /**
     Sets the consent category IDs the user has denied.
     
     - Parameter deniedIds: The denied consent category IDs.
     */
    @objc
    @discardableResult
    public func setDeniedConsentIds(_ deniedIds: [String]) -> Self {
        self.deniedConsentIds = deniedIds
        return self
    }
}
