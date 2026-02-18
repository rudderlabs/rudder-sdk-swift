//
//  HttpNetworkTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

#if !os(watchOS) // URLProtocol-based mocks don’t work on watchOS..
@Suite("HttpNetwork Tests")
class HttpNetworkTests {
    
    init() { MockProvider.setupMockURLSession() }
    deinit { MockProvider.teardownMockURLSession() }
    
    @Test("given a success request, when it returns success status code in range, then HttpNetwork returns expected data",
          arguments: [(200, "https://success.test.com"),
                      (201, "https://success.test.com"),
                      (202, "https://success.test.com"),
                      (204, "https://success.test.com"),
                      (299, "https://success.test.com")])
    func testSuccessStatusCodesInRange(_ statusCode: Int, url: String) async {
        let expectedData = Data("success".utf8)
        let result = await performRequest(statusCode: statusCode, data: expectedData, urlString: url)
        
        switch result {
        case .success(let data):
            #expect(data == expectedData)
        case .failure:
            #expect(Bool(false), "Expected success for status code \(statusCode)")
        case .none:
            #expect(Bool(false), "No result returned")
        }
    }
    
    @Test("given a failure request, when it returns failure status code, then HttpNetwork handles request failure properly",
          arguments: [(400, "https://failure.test.com"),
                      (401, "https://failure.test.com"),
                      (402, "https://failure.test.com"),
                      (404, "https://failure.test.com"),
                      (499, "https://failure.test.com"),
                      (500, "https://failure.test.com"),
                      (501, "https://failure.test.com"),
                      (504, "https://failure.test.com"),
                      (555, "https://failure.test.com")])
    func testFailureStatusCodeInRange(_ statusCode: Int, url: String) async {
        let result = await performRequest(statusCode: statusCode, urlString: url)
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
    
    @Test("given an error request, when encountering various network errors, then HttpNetwork handles them as networkUnavailable",
          arguments: [
            (URLError.Code.notConnectedToInternet, "https://error.test.com"),
            (URLError.Code.networkConnectionLost, "https://error.test.com"),
            (URLError.Code.cannotConnectToHost, "https://error.test.com"),
            (URLError.Code.dnsLookupFailed, "https://error.test.com"),
            (URLError.Code.cannotFindHost, "https://error.test.com"),
            (URLError.Code.dataNotAllowed, "https://error.test.com")
          ])
    func testNetworkErrorsInRange(_ errorCode: URLError.Code, url: String) async {
        let result = await performRequest(error: errorCode, urlString: url)
        expectHttpFailure(result, expectedError: .networkUnavailable, context: "\(errorCode)")
    }
    
    @Test("given SSL errors, when performing request, then HttpNetwork handles them as networkUnavailable",
          arguments: [
            (URLError.Code.serverCertificateHasBadDate, "https://ssl-error.test.com"),
            (URLError.Code.serverCertificateUntrusted, "https://ssl-error.test.com"),
            (URLError.Code.serverCertificateHasUnknownRoot, "https://ssl-error.test.com"),
            (URLError.Code.serverCertificateNotYetValid, "https://ssl-error.test.com"),
            (URLError.Code.clientCertificateRejected, "https://ssl-error.test.com"),
            (URLError.Code.clientCertificateRequired, "https://ssl-error.test.com"),
            (URLError.Code.secureConnectionFailed, "https://ssl-error.test.com")
          ])
    func testSSLErrorsReturnNetworkUnavailable(_ errorCode: URLError.Code, url: String) async {
        let result = await performRequest(error: errorCode, urlString: url)
        expectHttpFailure(result, expectedError: .networkUnavailable, context: "\(errorCode)")
    }

    @Test("given timeout error, when performing request, then HttpNetwork returns timeout error")
    func testTimeoutErrorReturnsTimeout() async {
        let result = await performRequest(error: .timedOut, urlString: "https://timeout.test.com")
        expectHttpFailure(result, expectedError: .timeout, context: "timedOut")
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
#endif
