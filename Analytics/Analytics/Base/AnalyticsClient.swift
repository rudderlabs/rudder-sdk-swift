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
    var userIdentityState: StateImpl<UserIdentity>
    
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
        let event = ScreenEvent(screenName: name, category: category, properties: properties, options: options)
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
        let event = GroupEvent(groupId: id, traits: traits, options: options)
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
        self.pluginChain.process(event: event)
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
                self.configuration.storage.write(value: data.jsonString, key: StorageKeys.sourceConfig)
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
     The unique anonymous ID for the user. If not already set, a new UUID is generated and stored.
     */
    var anonymousId: String {
        get {
            if let id: String = self.configuration.storage.read(key: StorageKeys.anonymousId) {
                return id
            } else {
                let newId = UUID().uuidString
                self.configuration.storage.write(value: newId, key: StorageKeys.anonymousId)
                return newId
            }
        }
        set {
            self.configuration.storage.write(value: newValue, key: StorageKeys.anonymousId)
        }
    }
}
