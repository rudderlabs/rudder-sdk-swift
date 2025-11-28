//
//  ObjCStandardIntegration.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 28/11/25.
//

import Foundation

// MARK: - ObjCStandardIntegration
/**
 An Objective-C compatible protocol that represents a standard integration plugin.
 
 This protocol provides an Objective-C interface to the Swift `StandardIntegration` protocol,
 allowing standard integrations maintained by RudderStack to be used in Objective-C codebases.
 
 **Caution:** This protocol is considered internal and may change without notice. It is intended
 solely for use within RudderStack-maintained repositories and should not be referenced by external clients.
 */
@objc(RSSStandardIntegration)
public protocol ObjCStandardIntegration: AnyObject {
    // This protocol serves as a marker interface for Objective-C compatibility
    // No additional methods are required as StandardIntegration is also a marker protocol
}

// MARK: - ObjCIntegrationCallback
/**
 An Objective-C compatible callback type for integration ready status.
 */
public typealias ObjCIntegrationCallback = @convention(block) (Any?, NSError?) -> Void

// MARK: - Analytics Extension for ObjC Integration Plugins
extension ObjCAnalytics {
    /**
     Adds an Objective-C integration plugin to the analytics instance.
     
     - Parameter objcPlugin: The Objective-C integration plugin to add.
     */
    @objc(addIntegration:)
    public func add(integration: ObjCIntegrationPlugin) {
        guard let adapter = ObjCIntegrationPluginAdapter(objcIntegration: integration) as? ObjCPlugin else { return }
        self.add(plugin: adapter)
    }
}
