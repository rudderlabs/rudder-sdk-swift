//
//  ObjCIntegrationPluginHelper.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 02/12/25.
//

import Foundation

// MARK: - ObjCIntegrationCallback
/**
 An Objective-C compatible callback type for integration ready status.
 */
public typealias ObjCIntegrationCallback = @convention(block) (Any?, NSError?) -> Void

// MARK: - RSSIntegrationPluginHelper
/**
 A helper class to manage Objective-C integration plugins within the analytics instance.
 */
@objc(RSSIntegrationPluginHelper)
open class ObjCIntegrationPluginHelper: NSObject {
    
    @objc public var analytics: ObjCAnalytics
    @objc public var integration: ObjCIntegrationPlugin
    
    var adaptedIntegration: IntegrationPlugin? {
        return self.analytics.analytics.integrationsController?.integrationPluginChain?.find(key: integration.key)
    }
    
    @objc
    public init(analytics: ObjCAnalytics, integration: ObjCIntegrationPlugin) {
        self.analytics = analytics
        self.integration = integration
    }
    
    @objc
    public func addPlugin(_ plugin: ObjCPlugin) {
        guard let adaptedIntegration else { return }
        let adaptedPlugin = ObjCPluginAdapter(objcPlugin: plugin)
        adaptedIntegration.add(plugin: adaptedPlugin)
    }
    
    @objc
    public func removePlugin(_ plugin: ObjCPlugin) {
        guard let adaptedIntegration else { return }
        let adaptedPlugin = ObjCPluginAdapter(objcPlugin: plugin)
        adaptedIntegration.remove(plugin: adaptedPlugin)
    }
    
    @objc
    public func onDestinationReady(_ callback: @escaping ObjCIntegrationCallback) {
        guard let adaptedIntegration else { return }
        adaptedIntegration.onDestinationReady { destination, _ in
            if let destination {
                callback(destination, nil)
            } else {
                callback(nil, NSError(domain: "Destination \(adaptedIntegration.key) is absent or disabled in dashboard.", code: -1))
            }
        }
    }
}
