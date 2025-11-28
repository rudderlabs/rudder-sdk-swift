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

// MARK: - ObjCStandardIntegrationAdapter
/**
 An adapter that bridges an Objective-C conforming standard integration plugin (`ObjCStandardIntegration`)
 to the Swift-native `StandardIntegration` protocol.

 This allows Objective-C standard integration plugins to be used seamlessly in the analytics pipeline.
 */
final class ObjCStandardIntegrationAdapter: ObjCIntegrationPluginAdapter, StandardIntegration {
    
    /// The wrapped Objective-C integration plugin instance.
    private let objcIntegration: ObjCIntegrationPlugin
    
    /**
     Initializes the adapter with a given `ObjCIntegrationPlugin`.

     - Parameter objcPlugin: The Objective-C integration plugin to adapt.
     */
    override init(objcIntegration: ObjCIntegrationPlugin) {
        self.objcIntegration = objcIntegration
        super.init(objcIntegration: objcIntegration)
    }
}
