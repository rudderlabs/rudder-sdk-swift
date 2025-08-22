//
//  EventUploadErrorTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 22/08/25.
//

import XCTest
@testable import RudderStackAnalytics

final class EventUploadErrorTests: XCTestCase {
    
    private var mockAnalytics: Analytics!
    private var eventQueue: EventQueue!
    private var defaultSession: URLSession?
    
    override func setUp() {
        super.setUp()
        mockAnalytics = MockProvider.clientWithDiskStorage
        eventQueue = EventQueue(analytics: mockAnalytics)
        
        URLProtocol.registerClass(MockURLProtocol.self)
        defaultSession = HttpNetwork.session
    }
    
    override func tearDown() {
        super.tearDown()
        mockAnalytics = nil
        eventQueue = nil
        
        if let session = defaultSession {
            HttpNetwork.session = session
        }
        URLProtocol.unregisterClass(MockURLProtocol.self)
        defaultSession = nil
    }
    
    func test_uploadBatchHandles400Error() async {
        // Given
        HttpNetwork.session = self.prepareMockUrlSession(with: 400)
        let event = TrackEvent(event: "integration_test", properties: ["test": "value"])
        
        // When
        eventQueue.put(event)
        // Wait for event to be processed and written to storage
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Trigger flush to rollover storage and start upload
        self.eventQueue.flush()
        // Wait for upload process and 400 error handling to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Then
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        XCTAssertTrue(dataItems.isEmpty, "Event should be removed after 400 error handling")
       
        // Cleanup
        await self.cleanUpStorage()
    }
}
   
// MARK: - Helper Methods

extension EventUploadErrorTests {
    
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
