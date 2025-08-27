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
    private var eventUploader: EventUploader!
    private var uploadChannel: AsyncChannel<String>!
    private var defaultSession: URLSession?
    
    override func setUp() {
        super.setUp()
        mockAnalytics = MockProvider.clientWithDiskStorage
        uploadChannel = AsyncChannel<String>()
        eventUploader = EventUploader(analytics: mockAnalytics, uploadChannel: uploadChannel)
        
        URLProtocol.registerClass(MockURLProtocol.self)
        defaultSession = HttpNetwork.session
    }
    
    override func tearDown() {
        super.tearDown()
        eventUploader?.stop()
        eventUploader = nil
        uploadChannel = nil
        mockAnalytics = nil
        
        if let session = defaultSession {
            HttpNetwork.session = session
        }
        URLProtocol.unregisterClass(MockURLProtocol.self)
        defaultSession = nil
    }
    
    func test_uploadBatchHandles400Error() async {
        // Given
        HttpNetwork.session = self.prepareMockUrlSession(with: 400)
        let event = TrackEvent(event: "error_400_test", properties: ["test": "value"])
        
        // Store event in analytics storage
        if let eventJson = event.jsonString {
            await mockAnalytics.configuration.storage.write(event: eventJson)
            await mockAnalytics.configuration.storage.rollover()
        }
        
        // When
        eventUploader.start()
        
        // Trigger upload by sending signal
        let expectation = expectation(description: "Upload should handle 400 error and remove batch")
        
        Task {
            try? uploadChannel.send("upload_signal")
            
            let startTime = Date()
            let timeout: TimeInterval = 2.0
            
            // Wait for upload processing
            while Date().timeIntervalSince(startTime) < timeout {
                let dataItems = await self.mockAnalytics.configuration.storage.read().dataItems
                if dataItems.isEmpty {
                    expectation.fulfill()
                    break
                }
                await Task.yield()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Then
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        XCTAssertTrue(dataItems.isEmpty, "Batch should be removed after 400 error")
        
        await self.cleanUpStorage()
    }
    
    func test_uploadBatchHandles413Error() async {
        // Given
        HttpNetwork.session = self.prepareMockUrlSession(with: 413)
        let event = TrackEvent(event: "error_413_test", properties: ["test": "value"])
        
        // Store event in analytics storage
        if let eventJson = event.jsonString {
            await mockAnalytics.configuration.storage.write(event: eventJson)
            await mockAnalytics.configuration.storage.rollover()
        }
        
        // When
        eventUploader.start()
        
        // Trigger upload by sending signal
        let expectation = expectation(description: "Upload should handle 413 error and remove batch")
        
        Task {
            try? uploadChannel.send("upload_signal")
            
            let startTime = Date()
            let timeout: TimeInterval = 2.0
            
            // Wait for upload processing
            while Date().timeIntervalSince(startTime) < timeout {
                let dataItems = await self.mockAnalytics.configuration.storage.read().dataItems
                if dataItems.isEmpty {
                    expectation.fulfill()
                    break
                }
                await Task.yield()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Then
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        XCTAssertTrue(dataItems.isEmpty, "Batch should be removed after 413 error")
        
        await self.cleanUpStorage()
    }
}
   
// MARK: - Helper Methods

extension EventUploadErrorTests {
    
    private func prepareMockUrlSession(with responseCode: Int) -> URLSession {
        MockURLProtocol.requestHandler = { _ in
            let json = responseCode == 200 ? ["status": "success"] : ["error": "Server error"]
            let data = try JSONSerialization.data(withJSONObject: json)
            return (responseCode, data, ["Content-Type": "application/json"])
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    private func cleanUpStorage() async {
        guard let analytics = mockAnalytics else { return }
        let dataItems = await analytics.configuration.storage.read().dataItems
        for item in dataItems {
            await analytics.configuration.storage.remove(batchReference: item.reference)
        }
    }
}
