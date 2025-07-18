import Testing
import RudderStackAnalytics
@testable import SwiftUIExampleApp

struct SetAnonymousIdPluginTests {
    
    @Test
    func test_customAnonymousId_isSet_whenInterceptingEvent() {
        given("a SetAnonymousIdPlugin with a custom anonymous ID") {
            let analytics = Analytics(configuration: createTestConfiguration())
            
            let customAnonymousId = "custom-test-anonymous-id-12345"
            let setAnonymousIdPlugin = SetAnonymousIdPlugin(anonymousId: customAnonymousId)
            analytics.add(plugin: setAnonymousIdPlugin)
            
            let event = MockEvent()
            event.anonymousId = "original-anonymous-id"
            
            when("the plugin intercepts the event") {
                let result = setAnonymousIdPlugin.intercept(event: event)
                
                then("it should replace the original anonymousId with the custom one") {
                    #expect(result != nil, "Expected the intercepted event to be non-nil")
                    #expect(result?.anonymousId == customAnonymousId, "Expected anonymousId to be replaced with custom value")
                }
            }
        }
    }
    
    @Test
    func test_emptyAnonymousId_isSetCorrectly() {
        given("a SetAnonymousIdPlugin with an empty string as anonymous ID") {
            let analytics = Analytics(configuration: createTestConfiguration())
            
            let emptyAnonymousId = ""
            let setAnonymousIdPlugin = SetAnonymousIdPlugin(anonymousId: emptyAnonymousId)
            analytics.add(plugin: setAnonymousIdPlugin)
            
            let event = MockEvent()
            event.anonymousId = "original-id"
            
            when("the plugin intercepts the event") {
                let result = setAnonymousIdPlugin.intercept(event: event)
                
                then("it should set the anonymousId to empty string") {
                    #expect(result != nil, "Expected the intercepted event to be non-nil")
                    #expect(result?.anonymousId == "", "Expected anonymousId to be set to empty string")
                }
            }
        }
    }
    
    @Test
    func test_veryLongAnonymousId_isHandledCorrectly() {
        given("a SetAnonymousIdPlugin with a very long anonymous ID") {
            let analytics = Analytics(configuration: createTestConfiguration())
            
            let longAnonymousId = String(repeating: "a", count: 1000)
            let setAnonymousIdPlugin = SetAnonymousIdPlugin(anonymousId: longAnonymousId)
            analytics.add(plugin: setAnonymousIdPlugin)
            
            let event = MockEvent()
            event.anonymousId = "short-id"
            
            when("the plugin intercepts the event") {
                let result = setAnonymousIdPlugin.intercept(event: event)
                
                then("it should correctly set the very long anonymousId") {
                    #expect(result != nil, "Expected the intercepted event to be non-nil")
                    #expect(result?.anonymousId == longAnonymousId, "Expected anonymousId to handle very long strings correctly")
                    #expect(result?.anonymousId?.count == 1000, "Expected anonymousId length to be preserved")
                }
            }
        }
    }

    private func createTestConfiguration() -> Configuration {
        return Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
    }
}
