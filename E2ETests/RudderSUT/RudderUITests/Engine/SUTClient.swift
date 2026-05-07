//
//  SUTClient.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

class SUTClient {

    // MARK: - Properties

    var baseURL: String

    // MARK: - Init

    init(baseURL: String) {
        self.baseURL = baseURL
    }
}

// MARK: - Requests

extension SUTClient {

    @discardableResult
    func post(_ path: String, body: [String: Any]) throws -> [String: Any] {
        guard let url = URL(string: baseURL + path),
              let payload = try? JSONSerialization.data(withJSONObject: body)
        else { throw SUTError.invalidRequest }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return try sendSync(request)
    }

    func get(_ path: String) throws -> [String: Any] {
        guard let url = URL(string: baseURL + path) else { throw SUTError.invalidRequest }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"

        return try sendSync(request)
    }
}

// MARK: - Internal

extension SUTClient {

    private func sendSync(_ request: URLRequest) throws -> [String: Any] {
        var result: [String: Any] = [:]
        var requestError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { semaphore.signal() }
            if let error {
                requestError = error
                return
            }
            if let data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                result = json
            }
        }.resume()

        semaphore.wait()
        if let error = requestError { throw error }
        return result
    }
}

// MARK: - Errors

enum SUTError: Error {
    case invalidRequest
    case unexpectedResponse
}
