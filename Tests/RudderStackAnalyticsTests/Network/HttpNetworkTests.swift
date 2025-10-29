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
        let successUrl = "https://success.test.com"
        let result = await performRequest(statusCode: statusCode, data: expectedData, urlString: successUrl)
        
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
        let testUrl = "https://test.com"
        let failureUrl = "https://failure.test.com"
        let result = await performRequest(statusCode: statusCode, urlString: failureUrl)
        guard let result else { return }
        
        if case .success = result {
            #expect(Bool(false), "Expected failure but got success")
        } else if case .failure(let error) = result {
            if let httpError = error as? HttpNetworkError {
                if case .requestFailed(let errorCode) = httpError {
                    #expect(errorCode == statusCode)
                } else {
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
        let errorUrl = "https://error.test.com"
        let result = await performRequest(error: errorCode, urlString: errorUrl)
        expectHttpFailure(result, expectedError: .networkUnavailable, context: "\(errorCode)")
    }
}

// MARK: - Helpers
extension HttpNetworkTests {
    private func makeRequest(urlString: String) -> URLRequest? {
        guard let url = URL(string: urlString) else {
            Issue.record("Can't create URL from string: \(urlString)")
            return nil
        }
        return URLRequest(url: url)
    }
    
    private func performRequest(statusCode: Int? = nil, data: Data? = nil, error: URLError.Code? = nil, urlString: String) async -> Result<Data, Error>? {
        if let errorCode = error {
            MockURLProtocol.requestHandler = { _ in throw URLError(errorCode) }
        } else {
            MockURLProtocol.requestHandler = { _ in (statusCode ?? 200, data, nil) }
        }
        
        guard let request = makeRequest(urlString: urlString) else { return nil }
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
