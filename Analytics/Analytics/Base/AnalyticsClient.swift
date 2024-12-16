//
//  AnalyticsClient.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/08/24.
//

import Foundation

// MARK: - Analytics
/**
 This class serves as the main interface to the SDK, allowing user interaction.
 */
@objcMembers
public class AnalyticsClient {
    public var configuration: Configuration
    
    private var pluginChain: PluginChain!
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.setup()
    }
}

// MARK: - Events
extension AnalyticsClient {
    
    // MARK: - Track
    public func track(name: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        let event = TrackEvent(event: name, properties: properties, options: options)
        self.process(event: event)
    }
    
    // MARK: - Screen
    public func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        let event = ScreenEvent(screenName: name, category: category, properties: properties, options: options)
        self.process(event: event)
    }
    
    // MARK: - Group
    public func group(id: String, traits: RudderTraits? = nil, options: RudderOptions? = nil) {
        let event = GroupEvent(groupId: id, traits: traits, options: options)
        self.process(event: event)
    }
    
    // MARK: - Flush
    public func flush() {
        self.pluginChain.apply { plugin in
            if let plugin = plugin as? RudderStackDataPlanePlugin {
                plugin.flush()
            }
        }
    }
}

// MARK: - Private functions
extension AnalyticsClient {
    private func setup() {
        self.collectConfiguration()
        
        self.pluginChain = PluginChain(analytics: self)
        
        //Sample plugin..
        self.pluginChain.add(plugin: POCPlugin())
        
        //Message plugin..
        self.pluginChain.add(plugin: RudderStackDataPlanePlugin())
        
        //ContextInfo plugin..
        self.pluginChain.add(plugin: DeviceInfoPlugin())
        self.pluginChain.add(plugin: LocaleInfoPlugin())
        self.pluginChain.add(plugin: OSInfoPlugin())
        self.pluginChain.add(plugin: ScreenInfoPlugin())
        self.pluginChain.add(plugin: TimeZoneInfoPlugin())
        self.pluginChain.add(plugin: AppInfoPlugin())
        self.pluginChain.add(plugin: LibraryInfoPlugin())
        self.pluginChain.add(plugin: NetworkInfoPlugin())
    }
    
    private func process(event: Message) {
        self.pluginChain.process(event: event)
    }
}

// MARK: - Backend Configuration
extension AnalyticsClient {
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
