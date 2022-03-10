//
//  RSConfig.swift
//  Rudder
//
//  Created by Pallab Maiti on 04/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc
open class RSConfig: NSObject {
    let writeKey: String
    var anonymousId: String?
    var dataPlaneUrl: String = RSConstants.RSDataPlaneUrl
    var flushQueueSize: Int = RSConstants.RSFlushQueueSize
    var dbCountThreshold: Int = RSConstants.RSDBCountThreshold
    var sleepTimeOut: Int = RSConstants.RSSleepTimeout
    var logLevel: RSLogLevel = RSLogLevel.none
    var configRefreshInterval: Int = RSConstants.RSConfigRefreshInterval
    var trackLifecycleEvents: Bool = RSConstants.RSTrackLifeCycleEvents
    var recordScreenViews: Bool = RSConstants.RSRecordScreenViews
    var controlPlaneUrl: String = RSConstants.RSControlPlaneUrl
    
    @objc
    public init(writeKey: String) {
        self.writeKey = writeKey
    }
    
    @discardableResult @objc
    public func dataPlaneURL(_ dataPlaneUrl: String) -> RSConfig {
        if let url = URL(string: dataPlaneUrl) {
            if let scheme = url.scheme, let host = url.host {
                if let port = url.port {
                    self.dataPlaneUrl = "\(scheme)://\(host):\(port)"
                } else {
                    self.dataPlaneUrl = "\(scheme)://\(host)"
                }
            }
        }
        return self
    }
    
    @discardableResult @objc
    public func anonymousId(_ flushQueueSize: Int) -> RSConfig {
        self.flushQueueSize = flushQueueSize
        return self
    }
    
    @discardableResult @objc
    public func flushQueueSize(_ anonymousId: String) -> RSConfig {
        self.anonymousId = anonymousId
        return self
    }
    
    @discardableResult @objc
    public func loglevel(_ logLevel: RSLogLevel) -> RSConfig {
        self.logLevel = logLevel
        return self
    }
    
    @discardableResult @objc
    public func withDBCountThreshold(_ dbCountThreshold: Int) -> RSConfig {
        self.dbCountThreshold = dbCountThreshold
        return self
    }
    
    @discardableResult @objc
    public func sleepTimeOut(_ sleepTimeOut: Int) -> RSConfig {
        self.sleepTimeOut = sleepTimeOut
        return self
    }
    
    @discardableResult @objc
    public func configRefreshInterval(_ configRefreshInterval: Int) -> RSConfig {
        self.configRefreshInterval = configRefreshInterval
        return self
    }
    
    @discardableResult @objc
    public func trackLifecycleEvents(_ trackLifecycleEvents: Bool) -> RSConfig {
        self.trackLifecycleEvents = trackLifecycleEvents
        return self
    }
    
    @discardableResult @objc
    public func recordScreenViews(_ recordScreenViews: Bool) -> RSConfig {
        self.recordScreenViews = recordScreenViews
        return self
    }
    
    @discardableResult @objc
    public func controlPlaneURL(_ controlPlaneUrl: String) -> RSConfig {
        if let url = URL(string: controlPlaneUrl) {
            if let scheme = url.scheme, let host = url.host {
                if let port = url.port {
                    self.controlPlaneUrl = "\(scheme)://\(host):\(port)"
                } else {
                    self.controlPlaneUrl = "\(scheme)://\(host)"
                }
            }
        }
        return self
    }
}
