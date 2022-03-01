//
//  Events.swift
//  Segment
//
//  Created by Cody Garvin on 11/30/20.
//

import Foundation

// MARK: - Typed Event Signatures

/*extension Analytics {
    // make a note in the docs on this that we removed the old "options" property
    // and they need to write a middleware/enrichment now.
    // the objc version should accomodate them if it's really needed.
    
    public func track<P: Codable>(name: String, properties: P?) {
        do {
            if let properties = properties {
                let jsonProperties = try JSON(with: properties)
                let event = TrackMessage(event: name, properties: jsonProperties)
                process(incomingEvent: event)
            } else {
                let event = TrackMessage(event: name, properties: nil)
                process(incomingEvent: event)
            }
            
        } catch {
            exceptionFailure("\(error)")
        }
    }
    
    public func track(name: String) {
        track(name: name, properties: nil as TrackMessage?)
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID (or email address) for this user. If you don't have a userId
    ///     but want to record traits, you should pass nil. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see https://segment.io/libraries/ios#ids
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    public func identify<T: Codable>(userId: String, traits: T?) {
        do {
            if let traits = traits {
                let jsonTraits = try JSON(with: traits)
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: jsonTraits))
                let event = IdentifyMessage(userId: userId, traits: jsonTraits)
                process(incomingEvent: event)
            } else {
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: nil))
                let event = IdentifyMessage(userId: userId, traits: nil)
                process(incomingEvent: event)
            }
        } catch {
            exceptionFailure("\(error)")
        }
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    public func identify<T: Codable>(traits: T) {
        do {
            let jsonTraits = try JSON(with: traits)
            store.dispatch(action: UserInfo.SetTraitsAction(traits: jsonTraits))
            let event = IdentifyMessage(traits: jsonTraits)
            process(incomingEvent: event)
        } catch {
            exceptionFailure("\(error)")
        }
    }

    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID (or email address) for this user. If you don't have a userId
    ///     but want to record traits, you should pass nil. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see https://segment.io/libraries/ios#ids
    public func identify(userId: String) {
        let event = IdentifyMessage(userId: userId, traits: nil)
        store.dispatch(action: UserInfo.SetUserIdAction(userId: userId))
        process(incomingEvent: event)
    }
    
    public func screen<P: Codable>(title: String, category: String? = nil, properties: P?) {
        do {
            if let properties = properties {
                let jsonProperties = try JSON(with: properties)
                let event = ScreenMessage(title: title, category: category, properties: jsonProperties)
                process(incomingEvent: event)
            } else {
                let event = ScreenMessage(title: title, category: category)
                process(incomingEvent: event)
            }
        } catch {
            exceptionFailure("\(error)")
        }
    }
    
    public func screen(title: String, category: String? = nil) {
        screen(title: title, category: category, properties: nil as ScreenMessage?)
    }

    public func group<T: Codable>(groupId: String, traits: T?) {
        do {
            if let traits = traits {
                let jsonTraits = try JSON(with: traits)
                let event = GroupMessage(groupId: groupId, traits: jsonTraits)
                process(incomingEvent: event)
            } else {
                let event = GroupMessage(groupId: groupId)
                process(incomingEvent: event)
            }
        } catch {
            exceptionFailure("\(error)")
        }
    }
    
    public func group(groupId: String) {
        group(groupId: groupId, traits: nil as GroupMessage?)
    }
    
    public func alias(newId: String) {
        let event = AliasMessage(newId: newId)
        store.dispatch(action: UserInfo.SetUserIdAction(userId: newId))
        process(incomingEvent: event)
    }
}

// MARK: - Untyped Event Signatures

extension Analytics {
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID (or email address) for this user. If you don't have a userId
    ///     but want to record traits, you should pass nil. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see https://segment.io/libraries/ios#ids
    ///   - properties: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    public func track(name: String, properties: [String: Any]? = nil) {
        var props: JSON? = nil
        if let properties = properties {
            do {
                props = try JSON(properties)
            } catch {
                exceptionFailure("\(error)")
            }
        }
        let event = TrackMessage(event: name, properties: props)
        process(incomingEvent: event)
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID (or email address) for this user. If you don't have a userId
    ///     but want to record traits, you should pass nil. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see https://segment.io/libraries/ios#ids
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    public func identify(userId: String, traits: [String: Any]? = nil) {
        do {
            if let traits = traits {
                let traits = try JSON(traits as Any)
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: traits))
                let event = IdentifyMessage(userId: userId, traits: traits)
                process(incomingEvent: event)
            } else {
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: nil))
                let event = IdentifyMessage(userId: userId, traits: nil)
                process(incomingEvent: event)
            }

        } catch {
            exceptionFailure("Could not parse traits.")
        }
    }
    
    /// Track a screen change with a title, category and other properties.
    /// - Parameters:
    ///   - screenTitle: The title of the screen being tracked.
    ///   - category: A category to the type of screen if it applies.
    ///   - properties: Any extra metadata associated with the screen. e.g. method of access, size, etc.
    public func screen(title: String, category: String? = nil, properties: [String: Any]? = nil) {
        var event = ScreenMessage(title: title, category: category, properties: nil)
        if let properties = properties {
            do {
                let jsonProperties = try JSON(properties)
                event = ScreenMessage(title: title, category: category, properties: jsonProperties)
            } catch {
                exceptionFailure("Could not parse properties.")
            }
        }
        process(incomingEvent: event)
    }
    
    /// Associate a user with a group such as a company, organization, project, etc.
    /// - Parameters:
    ///   - groupId: A unique identifier for the group identification in your system.
    ///   - traits: Traits of the group you may be interested in such as email, phone or name.
    public func group(groupId: String, traits: [String: Any]?) {
        var event = GroupMessage(groupId: groupId)
        if let traits = traits {
            do {
                let jsonTraits = try JSON(traits)
                event = GroupMessage(groupId: groupId, traits: jsonTraits)
            } catch {
                exceptionFailure("Could not parse traits.")
            }
        }
        process(incomingEvent: event)
    }
}
*/