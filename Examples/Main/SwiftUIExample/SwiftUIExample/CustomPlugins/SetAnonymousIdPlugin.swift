import Foundation
import RudderStackAnalytics

// MARK: - SetAnonymousIdPlugin
/**
 A plugin that sets a given `anonymousId` in the event payload for every event.
 
 **Note**: The `anonymousId` fetched using `Analytics.anonymousId` would be different from the `anonymousId` set here.
 
 Set this plugin just after the SDK initialization to set the custom `anonymousId` in the event payload for every event:
 ```swift
 analytics.add(SetAnonymousIdPlugin(anonymousId: "someAnonymousId"))
 ```
 
 - Parameter anonymousId: The anonymousId to be set in the event payload. Ensure to preserve this value across app launches.
 */
class SetAnonymousIdPlugin: Plugin {
    
    /// The type of plugin - processing events during the main processing stage
    var pluginType: PluginType = .onProcess
    
    /// Reference to the analytics client
    var analytics: Analytics?
    
    /// The custom anonymous ID to be set on all events
    private let anonymousId: String
    
    /**
     Initializes the SetAnonymousIdPlugin with a custom anonymous ID.
     
     - Parameter anonymousId: The custom anonymous ID to be set on all events
     */
    init(anonymousId: String) {
        self.anonymousId = anonymousId
    }
    
    /**
     Sets up the plugin with the analytics client.
     
     - Parameter analytics: The analytics client instance
     */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /**
     Intercepts events and replaces the anonymousId with the custom value.
     
     - Parameter event: The event to process
     - Returns: The event with the custom anonymousId set
     */
    func intercept(event: any Event) -> (any Event)? {
        return replaceAnonymousId(event: event)
    }
    
    /**
     Replaces the anonymousId in the event with the custom value.
     
     - Parameter event: The event to modify
     - Returns: The event with the updated anonymousId
     */
    private func replaceAnonymousId(event: any Event) -> any Event {
        LoggerAnalytics.debug("SetAnonymousIdPlugin: Replacing anonymousId: \(anonymousId) in the event payload")
        
        var updatedEvent = event
        updatedEvent.anonymousId = anonymousId
        
        return updatedEvent
    }
}

