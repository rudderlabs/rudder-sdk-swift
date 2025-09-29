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
        HttpNetwork.session = MockProvider.prepareMockDataPlaneSession(with: 400)
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
    
    func test_uploadBatchHandles401Error() async {
        // Given
        HttpNetwork.session = MockProvider.prepareMockDataPlaneSession(with: 401)
        let event = TrackEvent(event: "error_401_test", properties: ["test": "value"])
        
        // Store event in analytics storage
        if let eventJson = event.jsonString {
            await mockAnalytics.configuration.storage.write(event: eventJson)
            await mockAnalytics.configuration.storage.rollover()
        }
        
        // Verify analytics is initially active and storage has data
        XCTAssertTrue(mockAnalytics.isAnalyticsActive, "Analytics should be active initially")
        
        // When
        eventUploader.start()
        
        // Trigger upload by sending signal
        try? uploadChannel.send("upload_signal")
        
        await runAfter(0.5) {
            // Then
            // Verify analytics has been shutdown
            XCTAssertFalse(self.mockAnalytics.isAnalyticsActive, "Analytics should be shutdown after 401 error")
            
            // Verify all storage has been cleared
            let dataItems = await self.mockAnalytics.configuration.storage.read().dataItems
            XCTAssertTrue(dataItems.isEmpty, "All storage should be cleared after 401 error")
            
            await self.cleanUpStorage()
        }
    }

#if !os(watchOS)
    func test_uploadBatchHandles404Error() async {
        // Given
        HttpNetwork.session = MockProvider.prepareMockDataPlaneSession(with: 404)
        let event = TrackEvent(event: "error_404_test", properties: ["test": "value"])
        
        // Store event in analytics storage
        if let eventJson = event.jsonString {
            await mockAnalytics.configuration.storage.write(event: eventJson)
            await mockAnalytics.configuration.storage.rollover()
        }
        
        // Verify storage has data initially
        let initialDataItems = await mockAnalytics.configuration.storage.read().dataItems
        XCTAssertFalse(initialDataItems.isEmpty, "Storage should have data initially")
        
        // When
        eventUploader.start()
        
        // Trigger upload by sending signal
        try? uploadChannel.send("upload_signal")
        
        await runAfter(0.3) {
            // Then
            // Verify upload channel has been closed (uploader stopped)
            XCTAssertTrue(self.uploadChannel.isClosed, "Upload channel should be closed after 404 error")
            
            // Verify source config has been disabled
            XCTAssertFalse(self.mockAnalytics.sourceConfigState.state.value.source.isSourceEnabled, "Source should disabled after 404 error")
            
            await self.cleanUpStorage()
        }
    }
#endif

    func test_uploadBatchHandles413Error() async {
        // Given
        HttpNetwork.session = MockProvider.prepareMockDataPlaneSession(with: 413)
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
    
    private func cleanUpStorage() async {
        guard let analytics = mockAnalytics else { return }
        let dataItems = await analytics.configuration.storage.read().dataItems
        for item in dataItems {
            await analytics.configuration.storage.remove(batchReference: item.reference)
        }
    }
}
