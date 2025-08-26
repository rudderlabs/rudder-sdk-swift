//
//  MockURLProtocol.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 22/08/25.
//

import Foundation

/**
 A `URLProtocol` subclass for mocking HTTP responses in tests.
*/
final class MockURLProtocol: URLProtocol {
    
    /**
    Closure the test sets to provide a mocked response.
    - Returns: `(statusCode, responseData, headers)`
    */
    static var requestHandler: ((URLRequest) throws -> (Int, Data?, [String: String]?))?
    
    // MARK: - URLProtocol overrides
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        do {
            let (statusCode, data, headers) = try handler(request)
            
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            
            // Safely build HTTPURLResponse
            if let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            } else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            
            // Send body if available
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
            
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        /* Default implementation (no-op) */
    }
}
