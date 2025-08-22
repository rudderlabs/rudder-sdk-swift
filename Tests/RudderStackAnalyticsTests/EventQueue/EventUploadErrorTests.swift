//
//  EventUploadErrorTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 22/08/25.
//

import XCTest
@testable import RudderStackAnalytics

final class EventUploadErrorTests: XCTestCase {

    private var mockAnalytics: Analytics?
    private var defaultSession: URLSession?
    
    override func setUp() {
        super.setUp()
        mockAnalytics = MockProvider.clientWithDiskStorage
        URLProtocol.registerClass(MockURLProtocol.self)
        defaultSession = HttpNetwork.session
    }
    
    override func tearDown() {
        super.tearDown()
        mockAnalytics = nil
        if let session = defaultSession {
            HttpNetwork.session = session
        }
        URLProtocol.unregisterClass(MockURLProtocol.self)
        defaultSession = nil
    }
    
    func test_uploadBatchHandles400Error() async {
        guard let analytics = mockAnalytics else { return XCTFail("Analytics client not set up") }
        
        // Given - Track an event with a 400 Bad Request response
        HttpNetwork.session = self.prepareMockUrlSession(with: 400)
        analytics.track(name: "Event_Error_400")

        // When - Flush the event
        analytics.flush()
        
        // Then - Wait for error handling to complete and verify storage is empty
        await self.waitForCondition(timeout: 5.0) {
            let dataItems = await analytics.configuration.storage.read().dataItems
            return dataItems.isEmpty
        }
        
        // Final assertion
        let dataItems = await analytics.configuration.storage.read().dataItems
        XCTAssertTrue(dataItems.isEmpty, "Storage should be empty after 400 error handling")
        
        // Cleanup
        await self.cleanUpStorage()
    }
    
    // MARK: - Helper Methods
    
    private func waitForCondition(timeout: TimeInterval, condition: @escaping () async -> Bool) async {
        let startTime = Date()
        let checkInterval: TimeInterval = 0.05 // 50ms
        var lastCheckTime = startTime
        
        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return
            }
            
            // Wait for the check interval before next iteration
            while Date().timeIntervalSince(lastCheckTime) < checkInterval {
                await Task.yield()
            }
            lastCheckTime = Date()
        }
    }
    
    func prepareMockUrlSession(with responseCode: Int) -> URLSession {
        MockURLProtocol.requestHandler = { _ in
            let json = ["error": "Not Found"]
            let data = try JSONSerialization.data(withJSONObject: json)
            return (responseCode, data, ["Content-Type": "application/json"])
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    func cleanUpStorage() async {
        guard let analytics = mockAnalytics else { return }
        let dataItems = await analytics.configuration.storage.read().dataItems
        for item in dataItems {
            await analytics.configuration.storage.remove(eventReference: item.reference)
        }
    }
}
