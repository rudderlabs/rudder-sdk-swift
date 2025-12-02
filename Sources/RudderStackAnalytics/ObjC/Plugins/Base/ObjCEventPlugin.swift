//
//  ObjCEventPlugin.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 28/11/25.
//

import Foundation

// MARK: - ObjCEventPlugin
/**
 An Objective-C compatible protocol that extends the Plugin protocol to handle specific types of event payloads.
 
 This protocol provides an Objective-C interface to the Swift `EventPlugin` protocol,
 allowing event plugins to be implemented and used in Objective-C codebases.
 
 It builds upon the `ObjCPlugin` protocol, adding event-specific methods to facilitate targeted processing.
 */
@objc(RSSEventPlugin)
public protocol ObjCEventPlugin: ObjCPlugin {
    
    /**
     Processes an `ObjCIdentifyEvent` payload.
     
     - Parameter payload: The `ObjCIdentifyEvent` payload to be processed.
     */
    @objc
    optional func identify(_ payload: ObjCIdentifyEvent)
    
    /**
     Processes an `ObjCTrackEvent` payload.
     
     - Parameter payload: The `ObjCTrackEvent` payload to be processed.
     */
    @objc
    optional func track(_ payload: ObjCTrackEvent)
    
    /**
     Processes an `ObjCScreenEvent` payload.
     
     - Parameter payload: The `ObjCScreenEvent` payload to be processed.
     */
    @objc
    optional func screen(_ payload: ObjCScreenEvent)
    
    /**
     Processes an `ObjCGroupEvent` payload.
     
     - Parameter payload: The `ObjCGroupEvent` payload to be processed.
     */
    @objc
    optional func group(_ payload: ObjCGroupEvent)
    
    /**
     Processes an `ObjCAliasEvent` payload.
     
     - Parameter payload: The `ObjCAliasEvent` payload to be processed.
     */
    @objc
    optional func alias(_ payload: ObjCAliasEvent)
}
