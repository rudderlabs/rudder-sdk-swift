//
//  EventUploaderTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 23/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("EventUploader Tests")
class EventUploaderTests {
    var analytics: Analytics
    var mockStorage: MockStorage
    var eventUploader: EventUploader
    var uploadChannel: AsyncChannel<String>
    
    init() {
        mockStorage = MockStorage()
        let config = MockProvider.createMockConfiguration(storage: mockStorage)
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        config.flushPolicies = []
        
        analytics = Analytics(configuration: config)
        analytics.isAnalyticsActive = true
        
        // Create upload channel
        uploadChannel = AsyncChannel<String>()
        
        // Create EventUploader
        eventUploader = EventUploader(analytics: analytics, uploadChannel: uploadChannel)
        eventUploader.start()
    }
    
    deinit {
        MockProvider.teardownMockURLSession()
        eventUploader.stop()
        let storage = mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    // MARK: - Anonymous ID Extraction Tests
    
    @Test("given batch with valid anonymousId, when extracting anonymousId, then correct id is returned")
    func testExtractAnonymousIdFromValidBatch() async {
        let batchPayload = """
        {"userId": "12345", "anonymousId": "abc-123", "event": "test"}
        """
        
        let expectedAnonymousId = "abc-123"
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        #expect(extractedId == expectedAnonymousId)
    }
    
    @Test("given batch without anonymousId, when extracting, then nil is returned")
    func testExtractAnonymousIdFromBatchWithoutAnonymousId() async {
        let batchPayload = """
        {"userId": "12345", "event": "test"}
        """
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        #expect(extractedId == nil)
    }
    
    @Test("given invalid JSON batch, when extracting anonymousId, then nil is returned")
    func testExtractAnonymousIdFromInvalidJSON() async {
        let invalidBatchPayload = "invalid json content"
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(invalidBatchPayload)
        
        #expect(extractedId == nil)
    }
    
    @Test("given batch with multiple anonymousId entries, when extracting, then first match is returned")
    func testExtractAnonymousIdFromMultipleEntries() async {
        let batchPayload = """
        [
            {"anonymousId": "first-123", "event": "event1"},
            {"anonymousId": "second-456", "event": "event2"}
        ]
        """
        
        let expectedAnonymousId = "first-123"
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        #expect(extractedId == expectedAnonymousId)
    }
    
    // MARK: - Channel Operations Tests
    
    @Test("given EventUploader, when stopping, then uploadChannel is closed")
    func testStopClosesUploadChannel() async {
        eventUploader.stop()
        
        #expect(uploadChannel.isClosed)
    }
    
#if !os(watchOS) // URLProtocol-based mocks don’t work on watchOS..
    @Test("given EventUploader with non-retryable error 400, when upload batch, then does not retry and removes batch")
    func testUploadBatchWithNonRetryableError400DoesNotRetryAndRemovesBatch() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        // Configure mock to return 400 error (non-retryable)
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            return (statusCode: 400, data: nil, headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockStorage.batchCount == 0) // Batches should be deleted
    }
    
    @Test("given EventUploader with retryable error 502, when upload batch, then retries with backoff")
    func testUploadBatchWithRetryableError502RetriesWithBackoff() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        // Configure mock to return 502 error
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            
            if callCount == 1 {
                return (statusCode: 502, data: nil, headers: nil)
            } else {
                // Success after retry
                return (statusCode: 200, data: "".data(using: .utf8), headers: nil)
            }
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(callCount >= 2)
        #expect(mockStorage.batchCount == 0)
    }
    
    @Test("given EventUploader with network unavailable error, when upload batch, then retries")
    func testUploadBatchWithNetworkUnavailableErrorRetries() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        
        // Configure mock to simulate network unavailable
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                throw URLError(.notConnectedToInternet)
            } else {
                return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
            }
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(callCount >= 2)
        #expect(mockStorage.batchCount == 0)
    }
    
    @Test("given EventUploader with timeout error, when upload batch, then retries as retryable error")
    func testUploadBatchWithTimeoutErrorRetriesAsRetryableError() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        
        // Configure mock to simulate timeout
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                throw URLError(.timedOut)
            } else {
                return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
            }
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)

        #expect(callCount >= 2)
        #expect(mockStorage.batchCount == 0)
    }
    
    @Test("given EventUploader with non-retryable error 401, when upload batch, then stops uploader")
    func testUploadBatchWithNonRetryableError401StopsUploader() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        
        // Configure mock to return 401 error (invalid write key)
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            return (statusCode: 401, data: nil, headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(callCount == 1) // Should not have retried
        #expect(uploadChannel.isClosed) // Upload channel should be closed
        #expect(analytics.isAnalyticsShutdown) // Analytics should be shutdown
    }
    
    @Test("given EventUploader with non-retryable error 404, when upload batch, then stops uploader")
    func testUploadBatchWithNonRetryableError404StopsUploader() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        
        // Configure mock to return 404 error (source not found)
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            return (statusCode: 404, data: nil, headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(callCount == 1) // Should not have retried
        #expect(uploadChannel.isClosed) // Upload channel should be closed
        #expect(!analytics.isSourceEnabled) // Source should be disabled
    }
    
    @Test("given EventUploader with non-retryable error 413, when upload batch, then does not retry")
    func testUploadBatchWithNonRetryableError413DoesNotRetry() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        
        // Configure mock to return 413 error (payload too large)
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            return (statusCode: 413, data: nil, headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(callCount == 1) // Should not have retried
        #expect(mockStorage.batchCount == 0)
    }
    
    @Test("given EventUploader with successful response, when upload batch, then completes without retry")
    func testUploadBatchWithSuccessfulResponseCompletesWithoutRetry() async throws {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return
        }
        
        var callCount = 0
        
        // Configure mock to return success
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let successResponse = """
            {"success": "ok"}
            """.data(using: .utf8)
            return (statusCode: 200, data: successResponse, headers: ["Content-Type": "application/json"])
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(callCount == 1) // Should only be called once
        #expect(mockStorage.batchCount == 0)
    }
#endif
}

enum EventUploaderTestsIssue {
    static var prepareMockEventJson: String { "Can't prepare mock event json" }
    static var readStorageDataItem: String { "Can't read data item from storage" }
}

