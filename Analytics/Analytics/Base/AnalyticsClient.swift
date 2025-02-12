//
//  AnalyticsClient.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/08/24.
//

import Foundation

// MARK: - Analytics
/**
 The `AnalyticsClient` class provides functionality for tracking events, managing user information, and processing data through a chain of plugins. It allows developers to track user actions, screen views, and group-specific data while enabling modular and extensible processing using plugins.
 */
@objcMembers
public class AnalyticsClient {
    
    /**
     The configuration object for the analytics client. It contains settings and storage mechanisms
     required for the analytics system.
     */
    public var configuration: Configuration
    
    /**
     The chain of plugins used for processing events and managing additional analytics functionality.
     */
    private var pluginChain: PluginChain!
    
    /**
     The property used to manage and observe changes to the user's identity state within the application.
     */
    private var userIdentityState: StateImpl<UserIdentity>
    
    /**
     Initializes the `AnalyticsClient` with the given configuration.
     
     - Parameter configuration: The configuration object containing settings and storage details.
     */
    public init(configuration: Configuration) {
        self.configuration = configuration
        
        self.userIdentityState = createState(initialState: UserIdentity.initializeState(configuration.storage))
        
        self.setup()
    }
}

// MARK: - Events

extension AnalyticsClient {
    
    /**
     Tracks a custom event with the specified name and optional properties and options.
     
     - Parameters:
        - name: The name of the event to track.
        - properties: An optional object containing event-specific properties.
        - options: An optional object for providing additional options.
     */
    public func track(name: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        let event = TrackEvent(event: name, properties: properties, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Tracks a screen view event with the specified name, category, and optional properties and options.
     
     - Parameters:
        - name: The name of the screen.
        - category: An optional category associated with the screen.
        - properties: An Optional properties associated with the screen view.
        - options: An Optional options for additional customization.
     */
    public func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        let event = ScreenEvent(screenName: name, category: category, properties: properties, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Tracks a group event with the specified group ID, traits, and options.
     
     - Parameters:
        - id: The unique identifier of the group.
        - traits: An Optional traits associated with the group.
        - options: An Optional options for additional customization.
     */
    public func group(id: String, traits: RudderTraits? = nil, options: RudderOptions? = nil) {
        let event = GroupEvent(groupId: id, traits: traits, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Identifies a user and associates traits and other metadata with their profile.

     - Parameters:
        - userId: A unique identifier for the user being identified.
        - traits: Custom traits or attributes associated with the user. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
     */
    public func identify(userId: String, traits: RudderTraits? = nil, options: RudderOptions? = nil) {
        
        self.userIdentityState.dispatch(action: SetUserIdTraitsAndExternalIdsAction(userId: userId, traits: traits ?? RudderTraits(), externalIds: options?.externalIds ?? [], storage: self.storage))
        
        self.userIdentityState.state.value.storeUserIdTraitsAndExternalIds(self.storage)
        
        let event = IdentifyEvent(options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Alias a new user identifier with the existing user identity.

     - Parameters:
        - newId: The new user ID that should be associated with the previous ID.
        - previousId: The existing or previous user ID. If `nil`, the method resolves a preferred previous ID.
        - options: Additional options for customization, such as integrations and context. Defaults to `nil`.
     */
    public func alias(newId: String, previousId: String?, options: RudderOptions? = nil) {
        let preferedPreviousId = self.userIdentityState.state.value.resolvePreferredPreviousId(previousId ?? String.empty)
        
        self.userIdentityState.dispatch(action: SetUserIdAction(userId: newId))
        
        self.userIdentityState.state.value.storeUserId(self.storage)
        
        let event = AliasEvent(previousId: preferedPreviousId, options: options, userIdentity: self.userIdentityState.state.value)
        self.process(event: event)
    }
    
    /**
     Flushes all pending events by triggering the flush method on all plugins in the plugin chain.
     */
    public func flush() {
        self.pluginChain.apply { plugin in
            if let plugin = plugin as? RudderStackDataPlanePlugin {
                plugin.flush()
            }
        }
    }
    
    /**
     Resets the user identity state by clearing stored identifiers and traits.

     - Parameter clearAnonymousId: A boolean flag indicating whether the anonymous ID should be stored before resetting. Defaults to `false`.
    */
    public func reset(clearAnonymousId: Bool = false) {
        self.userIdentityState.dispatch(action: ResetUserIdentityAction(clearAnonymousId: clearAnonymousId))
        self.userIdentityState.state.value.resetUserIdentity(clearAnonymousId: clearAnonymousId, storage: self.storage)
    }
}

// MARK: - Plugin Management

extension AnalyticsClient {
    
    /**
     Adds a custom plugin to the plugin chain for processing events and extending functionality.
     
     - Parameter plugin: The plugin to be added.
     */
    public func addPlugin(_ plugin: Plugin) {
        self.pluginChain.add(plugin: plugin)
    }
}

// MARK: - Private Functions

extension AnalyticsClient {
    
    /**
     Sets up the analytics client by collecting configuration data and initializing the plugin chain.
     */
    private func setup() {
        self.storeAnonymousId()
        self.collectConfiguration()
        
        self.pluginChain = PluginChain(analytics: self)
        
        // Add default plugins
        self.pluginChain.add(plugin: RudderStackDataPlanePlugin())
        self.pluginChain.add(plugin: DeviceInfoPlugin())
        self.pluginChain.add(plugin: LocaleInfoPlugin())
        self.pluginChain.add(plugin: OSInfoPlugin())
        self.pluginChain.add(plugin: ScreenInfoPlugin())
        self.pluginChain.add(plugin: TimeZoneInfoPlugin())
        self.pluginChain.add(plugin: AppInfoPlugin())
        self.pluginChain.add(plugin: LibraryInfoPlugin())
        self.pluginChain.add(plugin: NetworkInfoPlugin())
    }
    
    /**
     Processes an event by passing it through the plugin chain.
     
     - Parameter event: The event to be processed.
     */
    private func process(event: Message) {
        let updatedEvent = event.updateEventData()
        self.pluginChain.process(event: updatedEvent)
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

extension AnalyticsClient {
    
    /**
     Collects configuration data from the backend and saves it in the storage.
     */
    private func collectConfiguration() {
        Task {
            let client = HttpClient(analytics: self)
            do {
                let data = try await client.getConfiguarationData()
                self.storage.write(value: data.jsonString, key: RSConstants.Storage.Keys.sourceConfig)
                print(data.prettyPrintedString ?? "Bad response")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - Common Variables

extension AnalyticsClient {
    
    /**
     A computed property for accessing and updating the `anonymousId` in the user identity state.

     - **Getter:**
        Retrieves the current `anonymousId` value from the `userIdentityState`.

     - **Setter:**
        Updates the `anonymousId` in the `userIdentityState` by dispatching a `SetAnonymousIdAction`.
        Additionally, persists the updated value by calling `storeAnonymousId`.
     */
    public var anonymousId: String {
        get {
            return self.userIdentityState.state.value.anonymousId
        }
        set {
            self.userIdentityState.dispatch(action: SetAnonymousIdAction(anonymousId: newValue))
            self.storeAnonymousId()
        }
    }
    
    /**
     A computed property that provides access to the storage instance from the configuration.

     This property retrieves the `Storage` instance associated with the current configuration.

     - Returns: The `Storage` instance from `self.configuration`.
     */
    var storage: Storage { self.configuration.storage }
}
