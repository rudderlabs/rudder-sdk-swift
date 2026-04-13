//
//  RequestCapture.swift
//  RudderStackAnalyticsTests
//
//  Created for E2E testing infrastructure.
//

import Foundation

/// A thread-safe container that captures HTTP requests made during E2E tests.
/// Used with `MockURLProtocol` to intercept and assert on outgoing batch requests.
final class RequestCapture: @unchecked Sendable {

    struct CapturedRequest: Sendable {
        let url: URL?
        let method: String?
        let headers: [String: String]?
        let body: Data?
    }

    private let lock = NSLock()
    private var requests: [CapturedRequest] = []

    func record(request: URLRequest) {
        let captured = CapturedRequest(
            url: request.url,
            method: request.httpMethod,
            headers: request.allHTTPHeaderFields,
            body: request.httpBody ?? request.httpBodyStream?.readAllData()
        )
        lock.lock()
        requests.append(captured)
        lock.unlock()
    }

    /// Returns the first captured POST /v1/batch request, or nil.
    private func findBatchRequest() -> CapturedRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.first {
            $0.method == "POST" && ($0.url?.path.contains("v1/batch") == true)
        }
    }

    /// Waits for a POST request to `/v1/batch`, polling at 10ms intervals.
    func waitForBatchRequest(timeout: TimeInterval = 5.0) async -> CapturedRequest? {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if let match = findBatchRequest() { return match }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        return nil
    }
}

// MARK: - InputStream helper

extension InputStream {
    func readAllData(bufferSize: Int = 1024) -> Data {
        var data = Data()
        open()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
            close()
        }
        while hasBytesAvailable {
            let bytesRead = read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        return data
    }
}
