//
//  ObjCScreenEvent.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 01/08/25.
//

import Foundation

// MARK: - ObjCScreenEvent
/**
 A class that provides an Objective-C compatible interface to the internal `ScreenEvent` model.
 
 Useful for exposing screen event data to Objective-C codebases, allowing manipulation
 of screen name, category, properties, and other screen-specific metadata.
 */
@objc(RSSScreenEvent)
public class ObjCScreenEvent: ObjCEvent {
    
    /**
     The underlying Swift `ScreenEvent` instance.
     */
    private var screenEvent: ScreenEvent {
        get {
            guard let screenEvent = event as? ScreenEvent else {
                fatalError("ObjCScreenEvent should only be initialized with ScreenEvent instances")
            }
            return screenEvent
        }
        set { event = newValue }
    }
    
    /**
     Initializes an `ObjCScreenEvent` with the given `ScreenEvent`.
     
     - Parameter event: The underlying Swift screen event model to wrap.
     */
    init(event: ScreenEvent) {
        super.init(event: event)
    }
    
    /**
     Initializes an `ObjCScreenEvent` with the specified screen name, category, properties, and options.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - category: The category of the screen, if applicable. Defaults to `nil`.
        - properties: Additional properties or metadata associated with the screen event. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information. Defaults to `nil`.
     */
    @objc
    public init(screenName: String, category: String? = nil, properties: [String: Any]? = nil, options: RudderOption? = nil, userIdentity: ObjCUserIdentity? = nil) {
        let swiftProperties = properties?.objCSanitized
        let swiftUserIdentity = userIdentity?.userIdentity
        
        let screenEvent = ScreenEvent(
            screenName: screenName,
            category: category,
            properties: swiftProperties,
            options: options,
            userIdentity: swiftUserIdentity
        )
        
        super.init(event: screenEvent)
    }

    /**
     Convenience initializer for creating a screen event with just a screen name.
     
     - Parameter screenName: The name of the screen or page being tracked.
     */
    @objc
    public convenience init(screenName: String) {
        self.init(screenName: screenName, category: nil, properties: nil, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a screen event with a screen name and category.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - category: The category of the screen.
     */
    @objc
    public convenience init(screenName: String, category: String) {
        self.init(screenName: screenName, category: category, properties: nil, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a screen event with a screen name and properties.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - properties: Additional properties or metadata associated with the screen event.
     */
    @objc
    public convenience init(screenName: String, properties: [String: Any]) {
        self.init(screenName: screenName, category: nil, properties: properties, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a screen event with a screen name and options.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - options: Additional options for screen tracking.
     */
    @objc
    public convenience init(screenName: String, options: RudderOption) {
        self.init(screenName: screenName, category: nil, properties: nil, options: options, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a screen event with a screen name, category, and properties.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - category: The category of the screen.
        - properties: Additional properties or metadata associated with the screen event.
     */
    @objc
    public convenience init(screenName: String, category: String, properties: [String: Any]) {
        self.init(screenName: screenName, category: category, properties: properties, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a screen event with a screen name, category, and options.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - category: The category of the screen.
        - options: Additional options for screen tracking.
     */
    @objc
    public convenience init(screenName: String, category: String, options: RudderOption) {
        self.init(screenName: screenName, category: category, properties: nil, options: options, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a screen event with a screen name, properties, and options.
     
     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - properties: Additional properties or metadata associated with the screen event.
        - options: Additional options for screen tracking.
     */
    @objc
    public convenience init(screenName: String, properties: [String: Any], options: RudderOption) {
        self.init(screenName: screenName, category: nil, properties: properties, options: options, userIdentity: nil)
    }

    // MARK: - Objective-C Compatible Properties

    /**
     The name of the screen or page being tracked.
     */
    @objc public var screenName: String {
        get { screenEvent.event }
        set { screenEvent.event = newValue }
    }

    /**
     The category of the screen, if any.
     */
    @objc public var category: String? {
        get { screenEvent.category }
        set { screenEvent.category = newValue }
    }

    /**
     Additional properties or metadata for the screen event.
     */
    @objc public var properties: [String: Any]? {
        get {
            screenEvent.properties?.dictionary?.rawDictionary
        }
        set {
            guard let dict = newValue?.objCSanitized else {
                screenEvent.properties = nil
                return
            }
            screenEvent.properties = CodableCollection(dictionary: dict)
        }
    }

    /**
     Custom options for the event, including integrations and context.
     */
    @objc public var options: RudderOption? {
        get { screenEvent.options }
        set { screenEvent.options = newValue }
    }

    /**
     The user's identity information associated with the event.
     */
    @objc public var userIdentity: ObjCUserIdentity? {
        get {
            guard let swiftUserIdentity = screenEvent.userIdentity else { return nil }
            return ObjCUserIdentity(userIdentity: swiftUserIdentity)
        }
        set {
            screenEvent.userIdentity = newValue?.userIdentity
        }
    }
}
