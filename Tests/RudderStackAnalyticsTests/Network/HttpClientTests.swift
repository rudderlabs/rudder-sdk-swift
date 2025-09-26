//
//  HttpClientTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Abhishek Pandey on 19/09/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

struct HttpClientTests {

    private let mockAnalytics: Analytics
    private let httpClient: HttpClient

    init() {
        mockAnalytics = MockProvider.clientWithDiskStorage
        httpClient = HttpClient(analytics: mockAnalytics)
    }
    
    @Test("Initializes with analytics anonymousId")
    func initializesWithAnalyticsAnonymousId() {
        let expectedAnonymousId = mockAnalytics.anonymousId ?? ""

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: expectedAnonymousId)
        #expect(headers["AnonymousId"] == expectedAnonymousId)
    }
    
    @Test("Update anonymousId header updates header correctly")
    func updateAnonymousIdHeader_updatesHeaderCorrectly() {
        let newAnonymousId = "new-anonymous-id-123"

        httpClient.updateAnonymousIdHeader(newAnonymousId)

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: newAnonymousId)
        #expect(headers["AnonymousId"] == newAnonymousId)
    }
    
    @Test("Events headers includes anonymousId header")
    func eventsHeaders_includesAnonymousIdHeader() {
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["AnonymousId"] == testAnonymousId)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Authorization"]?.hasPrefix("Basic ") == true)
    }
    
    @Test("Configuration headers does not include anonymousId header")
    func configurationHeaders_doesNotIncludeAnonymousIdHeader() {
        let testAnonymousId = "test-anonymous-id"

        let headers = HttpClientRequestType.configuration.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)

        #expect(headers["AnonymousId"] == nil)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Authorization"]?.hasPrefix("Basic ") == true)
    }
    
    @Test("Events headers with gzip enabled includes gzip header")
    func eventsHeaders_withGzipEnabled_includesGzipHeader() {
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
    
    @Test("Events headers without anonymousId uses analytics anonymousId")
    func eventsHeaders_withoutAnonymousId_usesAnalyticsAnonymousId() {
        let expectedAnonymousId = mockAnalytics.anonymousId ?? ""

        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: expectedAnonymousId)

        #expect(headers["AnonymousId"] == expectedAnonymousId)
    }
    
    @Test("Source Config requests has query params")
    func sourceConfigRequest_hasQueryParams() {
        let queryParams = Constants.defaultConfig.queryParams
        
        #expect(queryParams["p"] != nil, "Platform value should not be nil")
        #expect(queryParams["v"] == RSVersion, "SDK version should match")
        #expect(queryParams["bv"] != nil, "Build version value should not be nil")
        #expect(queryParams["writeKey"] == nil, "WriteKey should not be in Constants, it's added in HttpClient")
    }
    
    @Test("PrepareRequestUrl adds query parameters for configuration request")
    func prepareRequestUrl_addsQueryParametersForConfigurationRequest() {
        
        guard let url = httpClient.prepareRequestUrl(for: .configuration) as? URL else {
            #expect(Bool(false), "SourceConfig request URL should not be null.")
            return
        }
        
        let queryParameters = url.queryParameters
        
        #expect(queryParameters["p"] != nil, "Platform parameter should be present")
        #expect(queryParameters["v"] == RSVersion, "Version parameter should be present")
        #expect(queryParameters["bv"] != nil, "Build version value should not be nil")
        #expect(queryParameters["writeKey"] == mockAnalytics.configuration.writeKey)
    }
}
