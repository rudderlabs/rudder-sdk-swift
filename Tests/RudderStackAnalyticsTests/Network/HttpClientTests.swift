//
//  HttpClientTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Abhishek Pandey on 19/09/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("HttpClient Tests")
struct HttpClientTests {

    private let mockAnalytics: Analytics
    private let httpClient: HttpClient

    init() {
        mockAnalytics = MockProvider.createMockAnalytics()
        httpClient = HttpClient(analytics: mockAnalytics)
    }

    @Test("when initialized, then anonymousId header uses analytics anonymousId")
    func testInitUsesAnalyticsAnonymousId() {
        let expectedAnonymousId = mockAnalytics.anonymousId ?? ""

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: expectedAnonymousId)
        #expect(headers["AnonymousId"] == expectedAnonymousId)
    }

    @Test("when updating anonymousId header, then headers reflect new anonymousId")
    func testUpdateAnonymousIdHeader() {
        let newAnonymousId = "new-anonymous-id-123"

        httpClient.updateAnonymousIdHeader(newAnonymousId)

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: newAnonymousId)
        #expect(headers["AnonymousId"] == newAnonymousId)
    }

    @Test("when preparing configuration headers, then does not include anonymousId header")
    func testConfigHeadersExcludeAnonymousId() {
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.configuration.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["AnonymousId"] == nil)
    }

    @Test("when preparing events headers with gzip enabled, then omits gzip header")
    func testEventsHeadersExcludeGzipWhenEnabled() {
        let configuration = MockProvider.createMockConfiguration()
        configuration.gzipEnabled = true

        let gzipAnalytics = Analytics(configuration: configuration)
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.events.headers(gzipAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["Content-Encoding"] == nil)
        #expect(headers["AnonymousId"] == testAnonymousId)
    }

    @Test("when preparing source config request, then has correct query parameters")
    func testSourceConfigHasQueryParams() {
        let queryParams = Constants.defaultConfig.queryParams

        #expect(queryParams["p"] != nil, "Platform value should not be nil")
        #expect(queryParams["v"] == RSVersion, "SDK version should match")
        #expect(queryParams["bv"] != nil, "Build version value should not be nil")
        #expect(queryParams["writeKey"] == nil, "WriteKey should not be in Constants, it's added in HttpClient")
    }

    @Test("when preparing request URL for configuration, then adds correct query parameters")
    func testConfigUrlBuildsWithQueryParams() {

        guard let url = httpClient.prepareRequestUrl(for: .configuration) else {
            #expect(Bool(false), "SourceConfig request URL should not be null.")
            return
        }

        let queryParameters = url.queryParameters

        #expect(queryParameters["p"] != nil, "Platform parameter should be present")
        #expect(queryParameters["v"] == RSVersion, "Version parameter should be present")
        #expect(queryParameters["bv"] != nil, "Build version value should not be nil")
        #expect(queryParameters["writeKey"] == mockAnalytics.configuration.writeKey)
    }

#if !os(watchOS) // URLProtocol-based mocks don’t work on watchOS..
    @Test("given successful HTTP response, when requesting configuration data, then configuration data is returned successfully")
    func testGetConfigDataSuccess() async {
        MockProvider.setupMockURLSession()
        MockURLProtocol.forwardGetRequestsToHandler = true
        defer { MockProvider.teardownMockURLSession() }

        let expectedData = Data("{\"success\": true}".utf8)
        MockURLProtocol.requestHandler = { request in
            return (200, expectedData, _defaultHeaders)
        }

        let result = await httpClient.getConfigurationData()
        #expect(result.value == expectedData, "Expected success result with matching data")
    }

    @Test("given a failure HTTP response, when requesting configuration data, then the error is handled properly")
    func testGetConfigDataFailure() async {
        MockProvider.setupMockURLSession()
        MockURLProtocol.forwardGetRequestsToHandler = true
        defer { MockProvider.teardownMockURLSession() }

        MockURLProtocol.requestHandler = { request in
            return (400, nil, nil)
        }

        let result = await httpClient.getConfigurationData()
        #expect((result.error as? SourceConfigError) == .invalidWriteKey, "Expected invalidWriteKey error")
    }

    @Test("given successful HTTP response, when posting batch events, then handles success response")
    func testPostBatchEventsSuccess() async {
        MockProvider.setupMockURLSession()
        defer { MockProvider.teardownMockURLSession() }

        let eventBatch = "{\"batch\": [\"event1\", \"event2\"]}"
        let expectedResponseData = "{\"success\": true}".utf8Data

        MockURLProtocol.requestHandler = { request in
            return (200, expectedResponseData, _defaultHeaders)
        }

        let result = await httpClient.postBatchEvents(eventBatch)
        #expect(result.value == expectedResponseData, "Expected success result with matching data")
    }

    @Test("given gzip enabled, when posting batch events, then compresses body and sends gzip header")
    func testPostBatchEventsGzipEnabledSendsCompressedBodyAndHeader() async {
        MockProvider.setupMockURLSession()
        defer { MockProvider.teardownMockURLSession() }

        let configuration = MockProvider.createMockConfiguration()
        configuration.gzipEnabled = true
        let gzipClient = HttpClient(analytics: Analytics(configuration: configuration))
        let eventBatch = "{\"batch\": [\"event1\", \"event2\"]}"
        let rawBody = Data(eventBatch.utf8)
        let expectedResponseData = "{\"success\": true}".utf8Data
        var capturedContentEncoding: String?
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            capturedContentEncoding = request.value(forHTTPHeaderField: "Content-Encoding")
            capturedBody = bodyData(from: request)
            return (200, expectedResponseData, _defaultHeaders)
        }

        let result = await gzipClient.postBatchEvents(eventBatch)

        #expect(result.value == expectedResponseData, "Expected success result with matching data")
        #expect(capturedContentEncoding == "gzip")
        if let capturedBody {
            #expect(capturedBody.isGzipped)
            #expect(capturedBody != rawBody)
        } else {
            #expect(Bool(false), "Expected request body to be captured")
        }
    }

    @Test("given gzip disabled, when posting batch events, then sends uncompressed body without gzip header")
    func testPostBatchEventsGzipDisabledSendsUncompressedBodyWithoutHeader() async {
        MockProvider.setupMockURLSession()
        defer { MockProvider.teardownMockURLSession() }

        let eventBatch = "{\"batch\": [\"event1\", \"event2\"]}"
        let rawBody = Data(eventBatch.utf8)
        let expectedResponseData = "{\"success\": true}".utf8Data
        var capturedContentEncoding: String?
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            capturedContentEncoding = request.value(forHTTPHeaderField: "Content-Encoding")
            capturedBody = bodyData(from: request)
            return (200, expectedResponseData, _defaultHeaders)
        }

        let result = await httpClient.postBatchEvents(eventBatch)

        #expect(result.value == expectedResponseData, "Expected success result with matching data")
        #expect(capturedContentEncoding == nil)
        #expect(capturedBody == rawBody)
    }

    @Test("given gzip disabled and caller supplies gzip header, when posting batch events, then clears header")
    func testPostBatchEventsGzipDisabledClearsCallerSuppliedGzipHeader() async {
        MockProvider.setupMockURLSession()
        defer { MockProvider.teardownMockURLSession() }

        let eventBatch = "{\"batch\": [\"event1\", \"event2\"]}"
        let rawBody = Data(eventBatch.utf8)
        let expectedResponseData = "{\"success\": true}".utf8Data
        var capturedContentEncoding: String?
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            capturedContentEncoding = request.value(forHTTPHeaderField: "Content-Encoding")
            capturedBody = bodyData(from: request)
            return (200, expectedResponseData, _defaultHeaders)
        }

        let result = await httpClient.postBatchEvents(
            eventBatch,
            additionalHeaders: ["Content-Encoding": "gzip"]
        )

        #expect(result.value == expectedResponseData, "Expected success result with matching data")
        #expect(capturedContentEncoding == nil)
        #expect(capturedBody == rawBody)
    }

    @Test("given gzip compression fails, when posting batch events, then sends uncompressed body without gzip header")
    func testPostBatchEventsGzipFailureSendsUncompressedBodyWithoutHeader() async {
        MockProvider.setupMockURLSession()
        defer { MockProvider.teardownMockURLSession() }

        let configuration = MockProvider.createMockConfiguration()
        configuration.gzipEnabled = true
        let gzipClient = HttpClient(
            analytics: Analytics(configuration: configuration),
            gzipCompressor: { _ in throw StubCompressionError() }
        )
        let eventBatch = "{\"batch\": [\"event1\", \"event2\"]}"
        let rawBody = Data(eventBatch.utf8)
        let expectedResponseData = "{\"success\": true}".utf8Data
        var capturedContentEncoding: String?
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            capturedContentEncoding = request.value(forHTTPHeaderField: "Content-Encoding")
            capturedBody = bodyData(from: request)
            return (200, expectedResponseData, _defaultHeaders)
        }

        let result = await gzipClient.postBatchEvents(
            eventBatch,
            additionalHeaders: ["Content-Encoding": "gzip"]
        )

        #expect(result.value == expectedResponseData, "Expected success result with matching data")
        #expect(capturedContentEncoding == nil)
        #expect(capturedBody == rawBody)
    }

    @Test("given a failure HTTP response, when posting batch events failure, then the error is handled properly")
    func testPostBatchEventsFailure() async {
        MockProvider.setupMockURLSession()
        defer { MockProvider.teardownMockURLSession() }

        let batchData = "{\"batch\": []}"
        MockURLProtocol.requestHandler = { request in
            return (500, nil, nil)
        }

        let result = await httpClient.postBatchEvents(batchData)
        #expect(result.error is RetryableEventUploadError, "Expected retryable event upload error")
    }
#endif
}

// MARK: - Helpers

extension HttpClientTests {
    private var _defaultHeaders: [String: String] { ["Content-Type": "application/json"] }

    private func bodyData(from request: URLRequest) -> Data? {
        if let httpBody = request.httpBody {
            return httpBody
        }

        guard let httpBodyStream = request.httpBodyStream else { return nil }
        httpBodyStream.open()
        defer { httpBodyStream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while httpBodyStream.hasBytesAvailable {
            let bufferCount = buffer.count
            let bytesRead = buffer.withUnsafeMutableBufferPointer { pointer in
                guard let baseAddress = pointer.baseAddress else { return -1 }
                return httpBodyStream.read(baseAddress, maxLength: bufferCount)
            }
            guard bytesRead >= 0 else { return nil }
            guard bytesRead > 0 else { break }
            data.append(contentsOf: buffer.prefix(bytesRead))
        }
        return data
    }
}

struct StubCompressionError: Error {}

// MARK: - ResultExtractable

protocol ResultExtractable {
    var value: Data? { get }
    var error: Error? { get }
}

extension ResultExtractable {
    var value: Data? {
        switch self {
        case let result as SourceConfigResult:
            if case let .success(data) = result {
                return data
            }

        case let result as EventUploadResult:
            if case let .success(data) = result {
                return data
            }

        default:
            break
        }

        return nil
    }

    var error: Error? {
        switch self {
        case let result as SourceConfigResult:
            if case let .failure(error) = result {
                return error
            }

        case let result as EventUploadResult:
            if case let .failure(error) = result {
                return error
            }

        default:
            break
        }

        return nil
    }
}

extension SourceConfigResult: ResultExtractable {}
extension EventUploadResult: ResultExtractable {}
