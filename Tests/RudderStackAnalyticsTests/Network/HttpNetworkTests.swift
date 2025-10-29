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
    
    @Test("given a request, when it returns success status code in range, then HttpNetwork returns expected data",
          arguments: [200, 201, 202, 204, 299])
    func testSuccessStatusCodesInRange(_ statusCode: Int) async {
        let expectedData = Data("success".utf8)
        let result = await performRequest(statusCode: statusCode, data: expectedData)
        
        switch result {
        case .success(let data):
            #expect(data == expectedData)
        case .failure:
            #expect(Bool(false), "Expected success for status code \(statusCode)")
        case .none:
            #expect(Bool(false), "No result returned")
        }
    }
    
    @Test("given a request, when it returns failure status code, then HttpNetwork handles request failure properly",
          arguments: [400, 401, 402, 404, 499, 500, 501, 504, 555])
    func testFailureStatusCodeInRange(_ statusCode: Int) async {
        let result = await performRequest(statusCode: statusCode)
        guard let result else { return }
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let error):
            if let httpError = error as? HttpNetworkError {
                switch httpError {
                case .requestFailed(let errorCode):
                    #expect(errorCode == statusCode)
                default:
                    #expect(Bool(false), "Expected requestFailed error")
                }
            } else {
                #expect(Bool(false), "Expected HttpNetworkError")
            }
        }
    }
    
    @Test("given a request, when encountering various network errors, then HttpNetwork handles them as networkUnavailable",
          arguments: [
            URLError.Code.notConnectedToInternet,
            URLError.Code.networkConnectionLost,
            URLError.Code.cannotConnectToHost,
            URLError.Code.timedOut,
            URLError.Code.dnsLookupFailed,
            URLError.Code.cannotFindHost,
            URLError.Code.dataNotAllowed
          ])
    func testNetworkErrorsInRange(_ errorCode: URLError.Code) async {
        let result = await performRequest(error: errorCode)
        expectHttpFailure(result, expectedError: .networkUnavailable, context: "\(errorCode)")
    }
}

// MARK: - Helpers
extension HttpNetworkTests {
    private func makeRequest() -> URLRequest? {
        guard let url = URL(string: "https://test.com") else {
            Issue.record("Can't create URL from string")
            return nil
        }
        return URLRequest(url: url)
    }
    
    private func performRequest(statusCode: Int? = nil, data: Data? = nil, error: URLError.Code? = nil) async -> Result<Data, Error>? {
        if let errorCode = error {
            MockURLProtocol.requestHandler = { _ in throw URLError(errorCode) }
        } else {
            MockURLProtocol.requestHandler = { _ in (statusCode ?? 200, data, nil) }
        }
        
        guard let request = makeRequest() else { return nil }
        return await HttpNetwork.perform(request: request)
    }
    
    private func expectHttpFailure(_ result: Result<Data, Error>?, expectedError: HttpNetworkError, context: String) {
        guard let result else {
            #expect(Bool(false), "No result returned (\(context))")
            return
        }
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success (\(context))")
        case .failure(let error):
            guard let httpError = error as? HttpNetworkError else {
                #expect(Bool(false), "Expected HttpNetworkError (\(context))")
                return
            }
            #expect(httpError == expectedError, "Expected \(expectedError) but got \(httpError)")
        }
    }
}
