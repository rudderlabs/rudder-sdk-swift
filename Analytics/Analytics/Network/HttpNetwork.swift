//
//  HttpNetwork.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/09/24.
//

import Foundation

// MARK: - HttpNetworkError
/**
 Enum for basic network error states.
 */
enum HttpNetworkError: Error {
    case requestFailed(Int)
    case invalidResponse
}

// MARK: - HttpNetwork
/**
 This class handles all network calls, returning either response data or an error.
 */
final class HttpNetwork {
    
    private init() {}
    
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration)
    }()
    
    static func perform(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(HttpNetworkError.invalidResponse))
                return
            }
            
            let statusCode = httpResponse.statusCode
            guard let data = data, statusCode == 200 else {
                print(data?.jsonString ?? "No Data..")
                completion(.failure(HttpNetworkError.requestFailed(statusCode)))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
}
