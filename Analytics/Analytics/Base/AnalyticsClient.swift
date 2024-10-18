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
        let event = TrackEvent(event: name, properties: CodableDictionary(properties), options: CodableDictionary(options))
        self.process(event: event)
    }
    
    // MARK: - Flush
    public func flush() {
        self.process(event: FlushEvent(messageName: Constants.uploadSignal))
    }
}

// MARK: - Private functions
extension AnalyticsClient {
    private func setup() {
        self.pluginChain = PluginChain(analytics: self)
        self.pluginChain.add(plugin: POCPlugin())
        self.pluginChain.add(plugin: RudderStackDataPlanePlugin())
        
        Task {
            self.collectConfiguration()
        }
    }
    
    private func process(event: Message) {
        Task {
            self.pluginChain.process(event: event)
        }
    }
}

// MARK: - Backend Configuration
extension AnalyticsClient {
    private func collectConfiguration() {
        let client = HttpClient(analytics: self)
        client.getConfiguarationData { result in
            switch result {
            case .success(let response):
                print(response.prettyPrintedString ?? "Bad response")
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

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
