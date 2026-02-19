//
//  EventUploaderRetryHeadersTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/02/26.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("EventUploader Retry Headers Tests")
class EventUploaderRetryHeadersTests {
    var analytics: Analytics
    var mockStorage: MockStorage
    var mockRetryHeadersProvider: MockRetryHeadersProvider
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
        
        uploadChannel = AsyncChannel<String>()
        mockRetryHeadersProvider = MockRetryHeadersProvider()
        
        eventUploader = EventUploader(
            analytics: analytics,
            uploadChannel: uploadChannel,
            retryHeadersProvider: mockRetryHeadersProvider
        )
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
    
#if !os(watchOS)
    @Test("given successful upload, when uploading batch, then prepareHeaders is called")
    func testUploadCallsPrepareHeaders() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { _ in
            return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockRetryHeadersProvider.prepareHeadersCallCount == 1)
    }
    
    @Test("given retry headers configured, when uploading batch, then headers are sent in request")
    func testRetryHeadersAreSentInRequest() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        mockRetryHeadersProvider.headersToReturn = [
            RetryHeaderKeys.rsaRetryAttempt: "2",
            RetryHeaderKeys.rsaSinceLastAttempt: "500",
            RetryHeaderKeys.rsaRetryReason: "server-502"
        ]
        
        var capturedRequest: URLRequest?
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(capturedRequest?.value(forHTTPHeaderField: RetryHeaderKeys.rsaRetryAttempt) == "2")
        #expect(capturedRequest?.value(forHTTPHeaderField: RetryHeaderKeys.rsaSinceLastAttempt) == "500")
        #expect(capturedRequest?.value(forHTTPHeaderField: RetryHeaderKeys.rsaRetryReason) == "server-502")
    }
    
    @Test("given retryable error, when upload fails, then recordFailure is called")
    func testRecordFailureCalledOnRetryableError() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        var callCount = 0
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount == 1 {
                return (statusCode: 502, data: nil, headers: nil)
            }
            return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockRetryHeadersProvider.recordFailureCallCount == 1)
        #expect(mockRetryHeadersProvider.lastRecordFailureError == .retryable(statusCode: 502))
    }
    
    @Test("given non-retryable error, when upload fails, then recordFailure is not called")
    func testRecordFailureNotCalledOnNonRetryableError() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { _ in
            return (statusCode: 400, data: nil, headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockRetryHeadersProvider.recordFailureCallCount == 0)
    }
    
    @Test("given successful upload, when upload completes, then clear is called")
    func testClearCalledOnSuccess() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { _ in
            return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockRetryHeadersProvider.clearCallCount == 1)
    }
    
    @Test("given non-retryable error, when upload fails, then clear is called")
    func testClearCalledOnNonRetryableError() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { _ in
            return (statusCode: 400, data: nil, headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockRetryHeadersProvider.clearCallCount == 1)
    }
    
    @Test("given retryable then success, when uploading batch, then prepareHeaders called on each attempt")
    func testPrepareHeadersCalledOnRetryAttempt() async throws {
        guard let dataItem = await prepareBatchDataItem() else { return }
        
        var callCount = 0
        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount == 1 {
                return (statusCode: 502, data: nil, headers: nil)
            }
            return (statusCode: 200, data: "{}".data(using: .utf8), headers: nil)
        }
        
        await eventUploader.uploadBatch(dataItem.batch, reference: dataItem.reference)
        
        #expect(mockRetryHeadersProvider.prepareHeadersCallCount == 2)
    }
#endif
}

// MARK: - Helpers

extension EventUploaderRetryHeadersTests {
    private func prepareBatchDataItem() async -> EventDataItem? {
        guard let mockEventJson = MockProvider.mockTrackEvent.jsonString else {
            Issue.record("\(EventUploaderTestsIssue.prepareMockEventJson)")
            return nil
        }
        await mockStorage.write(event: mockEventJson)
        await mockStorage.rollover()
        
        guard let dataItem = await mockStorage.read().dataItems.first else {
            Issue.record("\(EventUploaderTestsIssue.readStorageDataItem)")
            return nil
        }
        return dataItem
    }
}
