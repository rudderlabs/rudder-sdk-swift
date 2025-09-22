//
//  HttpClientTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Abhishek Pandey on 19/09/25.
//

import XCTest
@testable import RudderStackAnalytics

final class HttpClientTests: XCTestCase {
    
    private var mockAnalytics: Analytics!
    private var httpClient: HttpClient!
    
    override func setUp() {
        super.setUp()
        mockAnalytics = MockProvider.clientWithDiskStorage
        httpClient = HttpClient(analytics: mockAnalytics)
    }
    
    override func tearDown() {
        super.tearDown()
        httpClient = nil
        mockAnalytics = nil
    }
    
    func test_initializesWithAnalyticsAnonymousId() {
        let expectedAnonymousId = mockAnalytics.anonymousId ?? ""
        
        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: expectedAnonymousId)
        XCTAssertEqual(headers["AnonymousId"], expectedAnonymousId)
    }
    
    func test_updateAnonymousIdHeader_updatesHeaderCorrectly() {
        let newAnonymousId = "new-anonymous-id-123"
        
        httpClient.updateAnonymousIdHeader(newAnonymousId)
        
        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: newAnonymousId)
        XCTAssertEqual(headers["AnonymousId"], newAnonymousId)
    }
    
    func test_eventsHeaders_includesAnonymousIdHeader() {
        let testAnonymousId = "test-anonymous-id"
        
        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)
        
        XCTAssertEqual(headers["AnonymousId"], testAnonymousId)
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertTrue(headers["Authorization"]?.hasPrefix("Basic ") == true)
    }
    
    func test_configurationHeaders_doesNotIncludeAnonymousIdHeader() {
        let testAnonymousId = "test-anonymous-id"
        
        let headers = HttpClientRequestType.configuration.headers(mockAnalytics, anonymousIdHeader: testAnonymousId)
        
        XCTAssertNil(headers["AnonymousId"])
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertTrue(headers["Authorization"]?.hasPrefix("Basic ") == true)
    }
    
    func test_eventsHeaders_withGzipEnabled_includesGzipHeader() {
        let configuration = Configuration(
            writeKey: "test-write-key",
            dataPlaneUrl: "https://test.com",
            gzipEnabled: true
        )
        let gzipAnalytics = Analytics(configuration: configuration)
        let testAnonymousId = "test-anonymous-id"
        
        let headers = HttpClientRequestType.events.headers(gzipAnalytics, anonymousIdHeader: testAnonymousId)
        
        XCTAssertEqual(headers["Content-Encoding"], "gzip")
        XCTAssertEqual(headers["AnonymousId"], testAnonymousId)
    }
    
    func test_eventsHeaders_withoutAnonymousId_usesAnalyticsAnonymousId() {
        let expectedAnonymousId = mockAnalytics.anonymousId ?? ""
        
        let headers = HttpClientRequestType.events.headers(mockAnalytics, anonymousIdHeader: expectedAnonymousId)
        
        XCTAssertEqual(headers["AnonymousId"], expectedAnonymousId)
    }
}
