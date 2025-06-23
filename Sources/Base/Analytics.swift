//
//  Analytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/08/24.
//

import Foundation

// MARK: - Analytics
/**
 The `Analytics` class provides functionality for tracking events, managing user information, and processing data through a chain of plugins. It allows developers to track user actions, screen views, and group-specific data while enabling modular and extensible processing using plugins.
 */
public class Analytics {
    
    /**
     The configuration object for the analytics client. It contains settings and storage mechanisms
     required for the analytics system.
     */
    private(set) public var configuration: Configuration
    
    /**
     The chain of plugins used for processing events and managing additional analytics functionality.
     */
    private var pluginChain: PluginChain?
    
    /**
     The property used to manage and observe changes to the user's identity state within the application.
     */
    private var userIdentityState: StateImpl<UserIdentity>
    
    /**
     A private asynchronous channel for queuing and processing events.
     */
    private var processEventChannel: AsyncChannel<Event>
    
    /**
     The handler instance responsible for managing lifecycle events and session-related operations.
     
     - Note: When this property is set, `startAutomaticSessionIfNeeded()` is automatically triggered to ensure the automatic session begins as required.
     */
    internal var lifecycleSessionWrapper: LifecycleSessionWrapper? {
        didSet {
            self.sessionHandler?.startAutomaticSessionIfNeeded()
        }
    }
    
    /**
     Tracks the shutdown state of the analytics instance.
     */
    private(set) var isAnalyticsShutdown: Bool = false
        
    /**
     Initializes the `Analytics` with the given configuration.
     
     - Parameter configuration: The configuration object containing settings and storage details.
     */
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.processEventChannel = AsyncChannel(capacity: Int.max)
        self.userIdentityState = createState(initialState: UserIdentity.initializeState(configuration.storage))
        self.setup()
    }
}

// MARK: - Session

extension Analytics {
    
    /**
     Starts a session with a given `id`, or generates one if not provided.
     
     - Parameter sessionId: An optional `UInt64` session ID. If `nil`, a new session ID is generated.
     */
    public func startSession(sessionId: UInt64? = nil) {
        guard self.isAnalyticsActive else { return }
        
        if let sessionId, String(sessionId).count < SessionConstants.minSessionIdLength {
            LoggerAnalytics.error(log: "Session ID should be at least \(SessionConstants.minSessionIdLength) characters long.")
            return
        }
        
        let newSessionId = sessionId ?? SessionHandler.generatedSessionId
        self.sessionHandler?.startSession(id: newSessionId, type: .manual)
    }
    
    /**
     Ends the current session.
     */
    public func endSession() {
        guard self.isAnalyticsActive else { return }
        self.sessionHandler?.endSession()
    }
    
    /**
     A computed property which returns the current active session id.
     
     - Returns: The `UInt64` value if active session exists else `nil`.
     */
    public var sessionId: UInt64? { self.isAnalyticsActive ? self.sessionHandler?.sessionId : nil }
}

// MARK: - Events

extension Analytics {
    
    /**
     Tracks a custom event with the specified name and optional properties and options.
     
     - Parameters:
        - name: The name of the event to track.
        - properties: An optional object containing event-specific properties. Defaults to `nil`.
        - options: An optional object for providing additional options. Defaults to `nil`.
     */
    public func track(name: String, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        guard self.isAnalyticsActive else { return }
        
        let event = TrackEvent(event: name, properties: properties, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Tracks a screen view event with the specified name, category, and optional properties and options.
     
     - Parameters:
        - screenName: The name of the screen.
        - category: An optional category associated with the screen. Defaults to `nil`.
        - properties: An Optional properties associated with the screen view. Defaults to `nil`.
        - options: An Optional options for additional customization. Defaults to `nil`.
     */
    public func screen(screenName: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        guard self.isAnalyticsActive else { return }
        
        let event = ScreenEvent(screenName: screenName, category: category, properties: properties, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Tracks a group event with the specified group ID, traits, and options.
     
     - Parameters:
        - groupId: The unique identifier of the group.
        - traits: An Optional traits associated with the group. Defaults to `nil`.
        - options: An Optional options for additional customization. Defaults to `nil`.
     */
    public func group(groupId: String, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        guard self.isAnalyticsActive else { return }
        
        let event = GroupEvent(groupId: groupId, traits: traits, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Identifies a user and associates traits and other metadata with their profile.
     
     - Parameters:
        - userId: A unique identifier for the user being identified.
        - traits: Custom traits or attributes associated with the user. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
     */
    public func identify(userId: String? = nil, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        guard self.isAnalyticsActive else { return }
        
        if let currentUserId = self.userId, !currentUserId.isEmpty,
           let newUserId = userId, !newUserId.isEmpty,
           currentUserId != newUserId {
            reset()
        }
        
        self.userIdentityState.dispatch(action: SetUserIdAndTraitsAction(userId: userId ?? "", traits: traits ?? RudderTraits(), storage: self.storage))
        self.userIdentityState.state.value.storeUserIdAndTraits(self.storage)
        
        let event = IdentifyEvent(options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Alias a new user identifier with the existing user identity.
     
     - Parameters:
        - newId: The new user ID that should be associated with the previous ID.
        - previousId: The existing or previous user ID. If `nil`, the method resolves a preferred previous ID. Defaults to `nil`.
        - options: Additional options for customization, such as integrations and context. Defaults to `nil`.
     */
    public func alias(newId: String, previousId: String? = nil, options: RudderOption? = nil) {
        guard self.isAnalyticsActive else { return }
        
        let preferedPreviousId = self.userIdentityState.state.value.resolvePreferredPreviousId(previousId ?? String.empty)
        self.userIdentityState.dispatch(action: SetUserIdAction(userId: newId))
        self.userIdentityState.state.value.storeUserId(self.storage)
        
        let event = AliasEvent(previousId: preferedPreviousId, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Flushes all pending events by triggering the flush method on all plugins in the plugin chain.
     */
    @objc
    public func flush() {
        guard self.isAnalyticsActive else { return }
        
        self.pluginChain?.apply { plugin in
            if let plugin = plugin as? RudderStackDataPlanePlugin {
                plugin.flush()
            }
        }
    }
    
    /**
     Resets the user identity state by clearing stored identifiers and traits.
     */
    public func reset() {
        guard self.isAnalyticsActive else { return }
        
        self.userIdentityState.dispatch(action: ResetUserIdentityAction())
        self.userIdentityState.state.value.resetUserIdentity(storage: self.storage)
        
        self.sessionHandler?.refreshSession()
    }
}

// MARK: - Plugin Management

extension Analytics {
    
    /**
     Adds a custom plugin to the plugin chain for processing events and extending functionality.
     
     - Parameter plugin: The plugin to be added.
     */
    public func add(plugin: Plugin) {
        guard self.isAnalyticsActive else { return }
        self.pluginChain?.add(plugin: plugin)
    }
    
    /**
     Removes an already added plugin from the plugin chain of processing events.
     
     - Parameter plugin: The plugin to be removed.
     */
    public func remove(plugin: Plugin) {
        guard self.isAnalyticsActive else { return }
        self.pluginChain?.remove(plugin: plugin)
    }
}

// MARK: - Shutdown

extension Analytics {
    /**
     Shuts down the analytics instance, ending all operations, removing plugins, and freeing resources.
     All events recorded before shutdown are saved to disk but are processed only after the next startup.
     
     - Note: This action is irreversible, but no saved data is lost.
     */
    public func shutdown() {
        guard self.isAnalyticsActive else { return }
        
        self.isAnalyticsShutdown = true
        self.processEventChannel.close()
        
        self.pluginChain?.removeAll()
        self.pluginChain = nil
        
        self.lifecycleSessionWrapper?.tearDown()
        self.lifecycleSessionWrapper = nil
    }
    
    /**
     Indicates whether the analytics instance is active.
     */
    var isAnalyticsActive: Bool {
        get {
            if isAnalyticsShutdown {
                LoggerAnalytics.error(log: Constants.log.shutdownMessage)
            }
            return !isAnalyticsShutdown
        }
        set {
            isAnalyticsShutdown = !newValue
        }
    }
}

// MARK: - Private Functions

extension Analytics {
    
    /**
     Sets up the analytics client by collecting configuration data and initializing the plugin chain.
     */
    private func setup() {
        self.storeAnonymousId()
        self.collectConfiguration()
        self.startProcessingEvents()
        
        self.pluginChain = PluginChain(analytics: self)
        self.lifecycleSessionWrapper = LifecycleSessionWrapper(analytics: self)
        
        // Add default plugins
        self.pluginChain?.add(plugin: RudderStackDataPlanePlugin())
        self.pluginChain?.add(plugin: DeviceInfoPlugin())
        self.pluginChain?.add(plugin: LocaleInfoPlugin())
        self.pluginChain?.add(plugin: OSInfoPlugin())
        self.pluginChain?.add(plugin: ScreenInfoPlugin())
        self.pluginChain?.add(plugin: TimeZoneInfoPlugin())
        self.pluginChain?.add(plugin: AppInfoPlugin())
        self.pluginChain?.add(plugin: LibraryInfoPlugin())
        self.pluginChain?.add(plugin: NetworkInfoPlugin())
        self.pluginChain?.add(plugin: SessionTrackingPlugin())
        self.pluginChain?.add(plugin: LifecycleTrackingPlugin())
    }
    
    /**
     Starts processing events from the `processEventChannel` stream. Processes an event by passing it through the plugin chain.
     */
    private func startProcessingEvents() {
        Task {
            for await event in self.processEventChannel.stream {
                let updatedEvent = event.updateEventData()
                self.pluginChain?.process(event: updatedEvent)
            }
        }
    }
    
    /**
     Sends an event to the `processEventChannel` asynchronously.
     
     - Parameter event: The `Event` to be sent.
     */
    private func process(event: Event) {
        Task {
            try await self.processEventChannel.send(event)
        }
    }
    
    /**
     Persists the current `anonymousId` to the storage.
     
     This method retrieves the current value of `anonymousId` from the `userIdentityState` and stores it in the configured storage.
     */
    private func storeAnonymousId() {
        self.userIdentityState.state.value.storeAnonymousId(self.storage)
    }
}

// MARK: - Backend Configuration

extension Analytics {
    
    /**
     Collects configuration data from the backend and saves it in the storage.
     */
    private func collectConfiguration() {
        Task {
            let client = HttpClient(analytics: self)
            do {
                let data = try await client.getConfigurationData()
                self.storage.write(value: data.jsonString, key: Constants.storageKeys.sourceConfig)
                LoggerAnalytics.info(log: data.prettyPrintedString ?? "Bad response")
            } catch {
                LoggerAnalytics.error(log: "Failed to get sourceConfig", error: error)
            }
        }
    }
}

// MARK: - Common Variables

extension Analytics {
    
    /**
     A computed property for accessing the `anonymousId` in the user identity state.
     
     - **Getter:**
     Retrieves the current `anonymousId` value from the `userIdentityState`.
     */
    public var anonymousId: String? {
        return self.isAnalyticsActive ? self.userIdentityState.state.value.anonymousId : nil
    }
    
    /**
     A computed property for accessing the `userId` in the current user identity state.
     */
    public var userId: String? {
        return self.isAnalyticsActive ? self.userIdentityState.state.value.userId : nil
    }
    
    /**
     A computed property for accessing the `traits` in the current user identity state.
     */
    public var traits: RudderTraits? {
        return self.isAnalyticsActive ? self.userIdentityState.state.value.traits : nil
    }
    
    /**
     A computed property that provides access to the storage instance from the configuration.
     
     This property retrieves the `Storage` instance associated with the current configuration.
     
     - Returns: The `Storage` instance from `self.configuration`.
     */
    var storage: Storage { self.configuration.storage }
}

// MARK: - DeepLink Tracking

extension Analytics {
    
    /**
     Handles a deep link URL by extracting its query parameters and tracking the event.

     This method checks if analytics tracking is active. If it is, it extracts query parameters
     from the provided URL, merges them with any additional options, and sends a tracking event.

     - Parameters:
        - url: The deep link `URL` to process and track.
        - options: An optional dictionary of additional metadata to include in the tracking event.
     */
    public func open(url: URL, options: [String: Any]? = nil) {
        guard self.isAnalyticsActive else { return }

        var properties: [String: Any] = url.queryParameters
        properties["url"] = url.absoluteString

        // Add additional options
        if let options = options {
            for (key, value) in options {
                properties[key] = value
            }
        }
        
        LoggerAnalytics.debug(log: "Deep Link Opened: \(url.absoluteString)")
        
        // Track the event
        self.track(name: "Deep Link Opened", properties: properties)
    }
}

// MARK: - Typealiases (Public)
/**
 A dictionary representing event properties with string keys and any values
 */
public typealias RudderProperties = [String: Any]

/**
 // A dictionary representing user traits with string keys and any values
 */
public typealias RudderTraits = [String: Any]
