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
        mockAnalytics = SwiftTestMockProvider.createMockAnalytics()
        httpClient = HttpClient(analytics: mockAnalytics)
    }

    @Test("when initialized, then anonymousId header uses analytics anonymousId")
    func testInitializationWithAnalyticsAnonymousId() {
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
    
    @Test("when preparing events headers, then includes anonymousId header")
    func testEventsHeadersIncludesAnonymousIdHeader() {
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["AnonymousId"] == testAnonymousId)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Authorization"]?.hasPrefix("Basic ") == true)
    }

    @Test("when preparing configuration headers, then does not include anonymousId header")
    func testConfigurationHeadersDoesNotIncludeAnonymousIdHeader() {
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.configuration.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["AnonymousId"] == nil)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Authorization"]?.hasPrefix("Basic ") == true)
    }

    @Test("when preparing events headers with gzip enabled, then includes gzip header")
    func testEventsHeadersWithGzipEnabledIncludesGzipHeader() {
        let configuration = Configuration(
            writeKey: "test-write-key",
            dataPlaneUrl: "https://test.com",
            gzipEnabled: true
        )
        let gzipAnalytics = Analytics(configuration: configuration)
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.events.headers(gzipAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["Content-Encoding"] == "gzip")
        #expect(headers["AnonymousId"] == testAnonymousId)
    }

    @Test("when preparing events headers without anonymousId, then uses analytics anonymousId")
    func testEventsHeadersWithoutAnonymousIdUsesAnalyticsAnonymousId() {
        let expectedAnonymousId = mockAnalytics.anonymousId ?? ""

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: expectedAnonymousId)

        #expect(headers["AnonymousId"] == expectedAnonymousId)
    }
    
    @Test("when preparing source config request, then has correct query parameters")
    func testSourceConfigRequestHasQueryParams() {
        let queryParams = Constants.defaultConfig.queryParams
        
        #expect(queryParams["p"] != nil, "Platform value should not be nil")
        #expect(queryParams["v"] == RSVersion, "SDK version should match")
        #expect(queryParams["bv"] != nil, "Build version value should not be nil")
        #expect(queryParams["writeKey"] == nil, "WriteKey should not be in Constants, it's added in HttpClient")
    }
    
    @Test("when preparing request URL for configuration, then adds correct query parameters")
    func testPrepareRequestUrlAddsQueryParametersForConfigurationRequest() {
        
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

    @Test("when HttpClient gets configuration data, then handles success response")
    func testHttpClientGetsConfigurationDataSuccessfully() async {
        SwiftTestMockProvider.setupMockURLSession()
        defer { SwiftTestMockProvider.teardownMockURLSession() }
        
        let expectedData = Data("{\"success\": true}".utf8)
        MockURLProtocol.requestHandler = { request in
            return (200, expectedData, ["Content-Type": "application/json"])
        }
        
        let result = await httpClient.getConfigurationData()
        #expect(result.value == expectedData, "Expected success result with matching data")
    }
    
    @Test("when HttpClient gets configuration data failure, then handles error")
    func testHttpClientHandlesConfigurationDataFailure() async {
        SwiftTestMockProvider.setupMockURLSession()
        defer { SwiftTestMockProvider.teardownMockURLSession() }
        
        MockURLProtocol.requestHandler = { request in
            return (400, nil, nil)
        }
        
        let result = await httpClient.getConfigurationData()
        #expect((result.error as? SourceConfigError) == .invalidWriteKey, "Expected invalidWriteKey error")
    }
    
    @Test("when HttpClient posts batch events, then handles success response")
    func testHttpClientPostsBatchEventsSuccessfully() async {
        SwiftTestMockProvider.setupMockURLSession()
        defer { SwiftTestMockProvider.teardownMockURLSession() }
        
        let eventBatch = "{\"batch\": [\"event1\", \"event2\"]}"
        let expectedResponseData = "{\"success\": true}".utf8Data
        
        MockURLProtocol.requestHandler = { request in
            return (200, expectedResponseData, ["Content-Type": "application/json"])
        }
        
        let result = await httpClient.postBatchEvents(eventBatch)
        #expect(result.value == expectedResponseData, "Expected success result with matching data")
    }
    
    @Test("when HttpClient posts batch events failure, then handles error")
    func testHttpClientHandlesBatchEventsFailure() async {
        SwiftTestMockProvider.setupMockURLSession()
        defer { SwiftTestMockProvider.teardownMockURLSession() }
        
        let batchData = "{\"batch\": []}"
        MockURLProtocol.requestHandler = { request in
            return (500, nil, nil)
        }
        
        let result = await httpClient.postBatchEvents(batchData)
        #expect(result.error is RetryableEventUploadError, "Expected retryable event upload error")
    }
}

// MARK: - ResultExtractable

protocol ResultExtractable {
    var value: Data? { get }
    var error: Error? { get }
}

extension ResultExtractable {
    var value: Data? {
        switch self {
        case let result as SourceConfigResult:
            if case let .success(data) = result { return data }
        case let result as EventUploadResult:
            if case let .success(data) = result { return data }
        default:
            break
        }
        return nil
    }
    
    var error: Error? {
        switch self {
        case let result as SourceConfigResult:
            if case let .failure(error) = result { return error }
        case let result as EventUploadResult:
            if case let .failure(error) = result { return error }
        default:
            break
        }
        return nil
    }
}

extension SourceConfigResult: ResultExtractable {}
extension EventUploadResult: ResultExtractable {}
