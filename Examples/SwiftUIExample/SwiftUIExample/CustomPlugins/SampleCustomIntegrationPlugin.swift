//
//  SampleCustomIntegrationPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Vishal Gupta on 16/10/25.
//

import Foundation
import RudderStackAnalytics

/**
 * Sample custom integration plugin.
 *
 * This is a sample custom integration plugin that demonstrates how to create a custom
 * integration plugin for RudderStack.
 * It implements the `IntegrationPlugin` protocol and overrides the required methods.
 *
 * To use it, simply add it to the `Analytics` instance of your app using `add` method.
 */
class SampleCustomIntegrationPlugin: IntegrationPlugin {
    
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    var key: String = "MyKey"
    
    private var destinationSdk: SampleDestinationSdk?
    
    /**
     * For custom integration plugins, the `destinationConfig` is an empty dictionary, so it is not used.
     */
    func create(destinationConfig: [String: Any]) throws {
        if destinationSdk == nil {
            let apiKey = "SomeCustomApiKey"
            destinationSdk = SampleDestinationSdk.create(apiKey: apiKey)
        }
    }
    
    // The update for custom integration will not be called. It is only added as an example.
    func update(destinationConfig: [String: Any]) throws {
        destinationSdk?.update()
    }
    
    func getDestinationInstance() -> Any? {
        return destinationSdk
    }
    
    func track(payload: TrackEvent) {
        destinationSdk?.track(event: payload.event, properties: payload.properties?.dictionary?.rawDictionary ?? [:])
    }
    
    func screen(payload: ScreenEvent) {
        destinationSdk?.screen(screenName: payload.event, properties: payload.properties?.dictionary?.rawDictionary ?? [:])
    }
    
    func group(payload: GroupEvent) {
        destinationSdk?.group(groupId: payload.groupId, traits: payload.traits?.dictionary?.rawDictionary ?? [:])
    }
    
    func identify(payload: IdentifyEvent) {
        let traits = analytics?.traits ?? [:]
        destinationSdk?.identifyUser(userId: payload.userId ?? "", traits: traits)
    }
    
    func alias(payload: AliasEvent) {
        destinationSdk?.aliasUser(userId: payload.userId ?? "", previousId: payload.previousId)
    }
    
    func flush() {
        destinationSdk?.flush()
    }
    
    func reset() {
        destinationSdk?.reset()
    }
}

class SampleDestinationSdk {
    
    private let key: String
    
    private init(key: String) {
        self.key = key
    }
    
    func track(event: String, properties: [String: Any]) {
        LoggerAnalytics.debug("SampleDestinationSdk: track event \(event) with properties \(properties)")
    }
    
    func screen(screenName: String, properties: [String: Any]) {
        LoggerAnalytics.debug("SampleDestinationSdk: screen event \(screenName) with properties \(properties)")
    }
    
    func group(groupId: String, traits: [String: Any]) {
        LoggerAnalytics.debug("SampleDestinationSdk: group event \(groupId) with traits \(traits)")
    }
    
    func identifyUser(userId: String, traits: [String: Any]) {
        LoggerAnalytics.debug("SampleDestinationSdk: identify user \(userId) with traits \(traits)")
    }
    
    func aliasUser(userId: String, previousId: String) {
        LoggerAnalytics.debug("SampleDestinationSdk: alias user \(userId) with previous ID \(previousId)")
    }
    
    func flush() {
        LoggerAnalytics.debug("SampleDestinationSdk: flush")
    }
    
    func reset() {
        LoggerAnalytics.debug("SampleDestinationSdk: reset")
    }
    
    func update() {
        LoggerAnalytics.debug("SampleDestinationSdk: update")
    }
    
    static func create(apiKey: String) -> SampleDestinationSdk {
        // Create SampleDestinationSdk SDK instance
        // Simulate a delay in creation if needed
        Thread.sleep(forTimeInterval: 1.0)
        LoggerAnalytics.debug("SampleDestinationSdk: SDK created with API key \(apiKey)")
        return SampleDestinationSdk(key: apiKey)
    }
}
