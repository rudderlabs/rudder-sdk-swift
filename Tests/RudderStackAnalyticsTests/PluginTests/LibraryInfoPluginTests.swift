//
//  LibraryInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("LibraryInfoPlugin Tests")
class LibraryInfoPluginTests {
    var libraryInfoPlugin: LibraryInfoPlugin
    
    init() {
        self.libraryInfoPlugin = LibraryInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds device context information", arguments:[
        SwiftTestMockProvider.mockTrackEvent as Event,
        SwiftTestMockProvider.mockScreenEvent as Event,
        SwiftTestMockProvider.mockIdentifyEvent as Event,
        SwiftTestMockProvider.mockGroupEvent as Event,
        SwiftTestMockProvider.mockAliasEvent as Event
    ])
    func test_pluginIntercept(_ event: Event) {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        libraryInfoPlugin.setup(analytics: analytics)
        
        let result = libraryInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["library"] != nil)
        guard let libraryInfo = context["library"] as? [String: Any] else {
            Issue.record("Library info not found")
            return
        }
        
        #expect(libraryInfo["name"] != nil)
        #expect(libraryInfo["version"] != nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        libraryInfoPlugin.setup(analytics: analytics)
        
        #expect(libraryInfoPlugin.analytics != nil)
        #expect(libraryInfoPlugin.pluginType == .preProcess)
    }
}
