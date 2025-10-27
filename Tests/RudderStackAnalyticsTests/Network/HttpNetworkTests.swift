//
//  HttpNetworkTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("HttpNetwork Tests")
class HttpNetworkTests {
    
    init() { SwiftTestMockProvider.setupMockURLSession() }
    deinit { SwiftTestMockProvider.teardownMockURLSession() }
    
    @Test("when request returns success status code in range, then HttpNetwork returns expected data", arguments: [200, 201, 202, 204, 299])
    func test_successStatusCodesInRange(_ statusCode: Int) async {
        let expectedData = Data("success".utf8)
        
        MockURLProtocol.requestHandler = { request in
            return (statusCode, expectedData, nil)
        }
        
        guard let url = URL(string: "https://test.com") else {
            Issue.record("Can't create URL from string")
            return
        }
        
        let request = URLRequest(url: url)
        let result = await HttpNetwork.perform(request: request)
        
        switch result {
        case .success(let data):
            #expect(data == expectedData)
        case .failure:
            #expect(Bool(false), "Expected success for status code \(statusCode)")
        }
    }
    
    @Test("when request returning failure status code, then HttpNetwork handles request failure properly", arguments: [400, 401, 402, 404, 499, 500, 501, 504, 555])
    func test_failureStatusCodeInRange(_ statusCode: Int) async {
        
        MockURLProtocol.requestHandler = { request in
            return (statusCode, nil, nil)
        }
        
        guard let url = URL(string: "https://test.com") else {
            Issue.record("Can't create URL from string")
            return
        }
        
        let request = URLRequest(url: url)
        let result = await HttpNetwork.perform(request: request)
        
        // Then
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let error):
            if let httpError = error as? HttpNetworkError {
                switch httpError {
                case .requestFailed(let statusCode):
                    #expect(statusCode == statusCode)
                default:
                    #expect(Bool(false), "Expected requestFailed error")
                }
            } else {
                #expect(Bool(false), "Expected HttpNetworkError")
            }
        }
    }
    
    
    @Test("HttpNetwork handles various network errors as networkUnavailable", arguments: [
        URLError.Code.notConnectedToInternet,
        URLError.Code.networkConnectionLost,
        URLError.Code.cannotConnectToHost,
        URLError.Code.timedOut,
        URLError.Code.dnsLookupFailed,
        URLError.Code.cannotFindHost,
        URLError.Code.dataNotAllowed
    ])
    func handleVariousNetworkErrors(_ errorCode: URLError.Code) async {
        MockURLProtocol.requestHandler = { request in
            throw URLError(errorCode)
        }
        
        guard let url = URL(string: "https://test.com") else {
            Issue.record("Can't create URL from string")
            return
        }

        let request = URLRequest(url: url)
        let result = await HttpNetwork.perform(request: request)
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success for \(errorCode)")
        case .failure(let error):
            if let httpError = error as? HttpNetworkError {
                switch httpError {
                case .networkUnavailable:
                    break // ✅ Expected
                default:
                    #expect(Bool(false), "Expected networkUnavailable error for \(errorCode)")
                }
            } else {
                #expect(Bool(false), "Expected HttpNetworkError for \(errorCode)")
            }
        }
    }
}
