//
//  Analytics.swift
//  analytics-swift
//
//  Created by Brandon Sneed on 11/17/20.
//

import Foundation

// MARK: - Base Setup

@objc
open class RSClient: NSObject {
    internal var config: RSConfig
    public var timeline: RSController
    internal var serverConfig: RSServerConfig?
    internal var databaseManager: RSDatabaseManager
    internal var error: NSError?
    
    /// Initialize this instance of RSClient with a given configuration setup.
    /// - Parameters:
    ///    - config: The configuration to use
    @objc
    public init(config: RSConfig) {
        self.config = config
        serverConfig = RSUserDefaults.getServerConfig()
        databaseManager = RSDatabaseManager()
        timeline = RSController()
        
        super.init()
        addPlugins()
    }
    
    /**
     API for track your event
     - Parameters:
        - eventName: Name of the event you want to track
        - properties: Properties you want to pass with the track call
        - option: Options related to this track call
     # Example #
     ```
     let option = RSOption()
     RSClient.sharedInstance().track("Button clicked", properties: [:], option: option)
     ```
     */

    @objc
    public func track(_ eventName: String, properties: [String: Any]? = nil, option: RSOption? = nil) {
        let message = TrackMessage(event: eventName, properties: properties, option: option)
            .applyRawEventData()
        process(event: message)
    }
    
    /**
     API for record screen
     - Parameters:
        - screenName: Name of the screen
        - properties: Properties you want to pass with the screen call
        - option: Options related to this screen call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().screen("MyViewController", properties: [:], options: options)
     ```
     */
    
    @objc
    public func screen(_ screenName: String, properties: [String: String]? = nil, option: RSOption? = nil) {
        let message = ScreenMessage(title: screenName, properties: properties, option: option)
            .applyRawEventData()
        process(event: message)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - groupId: Group ID you want your user to attach to
        - traits: Traits of the group
        - option: Options related to this group call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("A1", traits: [:], options: options)
     ```
     */
    
    @objc
    public func group(_ groupId: String, traits: [String: String]? = nil, option: RSOption? = nil) {
        let message = GroupMessage(groupId: groupId, traits: traits, option: option)
            .applyRawEventData()
        process(event: message)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - newId: New userId for the user
        - option: Options related to this alias call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("U1", options: options)
     ```
     */
    
    @objc
    public func alias(_ newId: String, option: RSOption? = nil) {
        let message = AliasMessage(newId: newId, option: option)
            .applyAlias(newId: newId, client: self)
            .applyRawEventData()
        setUserId(newId)
        process(event: message)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - userId: User id of your user
        - traits: Other user properties
        - option: Options related to this identify call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("U1", traits: [:], options: options)
     ```
     */
    
    @objc
    public func identify(_ userId: String, traits: [String: String]? = nil, option: RSOption? = nil) {
        let message = IdentifyMessage(userId: userId, traits: traits, option: option)
            .applyRawEventData()
        setUserId(userId)
        process(event: message)
    }
        
    internal func process(event: RSMessage) {
        switch event {
        case let e as TrackMessage:
            timeline.process(incomingEvent: e)
        case let e as IdentifyMessage:
            timeline.process(incomingEvent: e)
        case let e as ScreenMessage:
            timeline.process(incomingEvent: e)
        case let e as GroupMessage:
            timeline.process(incomingEvent: e)
        case let e as AliasMessage:
            timeline.process(incomingEvent: e)
        default:
            break
        }
    }
}

// MARK: - System Modifiers

extension RSClient {
    /// Returns the anonymousId currently in use.
    public var anonymousId: String {
        if let anonymousId = RSUserDefaults.getAnonymousId() {
            return anonymousId
        }
        return ""
    }
    
    /// Returns the userId that was specified in the last identify call.
    public var userId: String? {
        if let userIdPlugin = self.find(pluginType: RSUserIdPlugin.self) {
            return userIdPlugin.userId
        }
        return nil
    }
    
    /// Returns the traits that were specified in the last identify call.
    public var context: [String: Any]? {
//        if let contextPlugin = self.find(pluginType: RSContextPlugin.self) {
//            return contextPlugin.userId
//        }
        return nil
    }
    
    /// Tells this instance of Analytics to flush any queued events up to Segment.com.  This command will also
    /// be sent to each plugin present in the system.
    public func flush() {
        apply { plugin in
            if let p = plugin as? RSEventPlugin {
                p.flush()
            }
        }
    }
    
    /// Resets this instance of Analytics to a clean slate.  Traits, UserID's, anonymousId, etc are all cleared or reset.  This
    /// command will also be sent to each plugin present in the system.
    public func reset() {
        apply { plugin in
            if let p = plugin as? RSEventPlugin {
                p.reset()
            }
        }
    }
    
    /// Retrieve the version of this library in use.
    /// - Returns: A string representing the version in "BREAKING.FEATURE.FIX" format.
    public func version() -> String {
        return RSConstants.RSVersion
    }
}

extension RSClient {
    /// Manually retrieve the settings that were supplied from Segment.com.
    /// - Returns: A Settings object containing integration settings, tracking plan, etc.
    public func configuration() -> RSConfig? {
        return config
    }
    
    /// Manually enable a destination plugin.  This is useful when a given DestinationPlugin doesn't have any Segment tie-ins at all.
    /// This will allow the destination to be processed in the same way within this library.
    /// - Parameters:
    ///   - plugin: The destination plugin to enable.
//    public func manuallyEnableDestination(plugin: DestinationPlugin) {
//        self.store.dispatch(action: System.AddDestinationToSettingsAction(key: plugin.key))
//    }

}

extension RSClient {
    /**
     Applies the supplied closure to the currently loaded set of plugins.
     NOTE: This does not apply to plugins contained within DestinationPlugins.
     
     - Parameter closure: A closure that takes an plugin to be operated on as a parameter.
     
     */
    func apply(closure: (RSPlugin) -> Void) {
        timeline.apply(closure)
    }
    
    /**
     Adds a new plugin to the currently loaded set.
     
     - Parameter plugin: The plugin to be added.
     - Returns: Returns the name of the supplied plugin.
     
     */
    @discardableResult
    func add(plugin: RSPlugin) -> RSPlugin {
        plugin.configure(analytics: self)
        timeline.add(plugin: plugin)
        return plugin
    }
    
    /**
     Removes and unloads plugins with a matching name from the system.
     
     - Parameter pluginName: An plugin name.
     */
    func remove(plugin: RSPlugin) {
        timeline.remove(plugin: plugin)
    }
    
    func find<T: RSPlugin>(pluginType: T.Type) -> T? {
        return timeline.find(pluginType: pluginType)
    }
}

extension RSClient {
    internal func update(serverConfig: RSServerConfig, type: UpdateType) {
        apply { (plugin) in
            // tell all top level plugins to update.
            update(plugin: plugin, serverConfig: serverConfig, type: type)
        }
    }
    
    internal func update(plugin: RSPlugin, serverConfig: RSServerConfig, type: UpdateType) {
        plugin.update(serverConfig: serverConfig, type: type)
        // if it's a destination, tell it's plugins to update as well.
        if let dest = plugin as? RSDestinationPlugin {
            dest.apply { (subPlugin) in
                subPlugin.update(serverConfig: serverConfig, type: type)
            }
        }
    }
    
    internal func checkSettings() {
        var retryCount = 0
        var isCompleted = false
        while !isCompleted && retryCount < 4 {
            if let serverConfig = fetchServerConfig() {
                self.serverConfig = serverConfig
                RSUserDefaults.saveServerConfig(serverConfig)
                RSUserDefaults.updateLastUpdatedTime(RSUtils.getTimeStamp())
                logDebug("server config download successful")
                isCompleted = true
            } else {
                if error?.code == RSErrorCode.WRONG_WRITE_KEY.rawValue {
                    logDebug("Wrong write key")
                    retryCount = 4
                } else {
                    logDebug("Retrying download in \(retryCount) seconds")
                    retryCount += 1
                    sleep(UInt32(retryCount))
                }
            }
        }
        if !isCompleted {
            logDebug("Server config download failed.Using last stored config from storage")
        }
    }
    
    private func fetchServerConfig() -> RSServerConfig? {
        var serverConfig: RSServerConfig?
        let semaphore = DispatchSemaphore(value: 0)
        let hasSettings = RSUserDefaults.getServerConfig() != nil
        let updateType = (hasSettings ? UpdateType.refresh : UpdateType.initial)
        let serviceManager = RSServiceManager(client: self)
        serviceManager.downloadServerConfig { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let config):
                serverConfig = config
                self.update(serverConfig: config, type: updateType)
            case .failure(let error):
                self.error = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        return serverConfig
    }
}
