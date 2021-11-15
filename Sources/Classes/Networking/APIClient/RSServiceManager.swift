//
//  RSServiceManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 05/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

typealias Handler<T> = (HandlerResult<T, NSError>) -> Void

enum HandlerResult<Success, Failure> {
    case success(Success)
    case failure(Failure)
}

struct RSServiceManager: RSServiceType {
    static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }()
    
    func downloadServerConfig(_ completion: @escaping Handler<RSServerConfig>) {
        RSServiceManager.request(.downloadConfig, completion)
    }
    
    func flushEvents(params: String, _ completion: @escaping Handler<Bool>) {
        RSServiceManager.request(.flushEvents(params: params), completion)
    }
}

extension RSServiceManager {
    static func request<T: Codable>(_ API: API, _ completion: @escaping Handler<T>) {
        let urlString = [API.baseURL, API.path].joined().addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        logDebug("RSServiceManager: URL: \(urlString ?? "")")
        var request = URLRequest(url: URL(string: urlString ?? "")!)
        request.httpMethod = API.method.value
        if let headers = API.headers {
            request.allHTTPHeaderFields = headers
            logDebug("RSServiceManager: HTTPHeaderFields: \(headers)")
        }
        if let httpBody = API.httpBody {
            request.httpBody = httpBody
            logDebug("RSServiceManager: httpBody: \(httpBody)")
        }
        let dataTask = RSServiceManager.sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(.failure(NSError(code: .SERVER_ERROR)))
                    return
                }
                let response = response as? HTTPURLResponse
                if let statusCode = response?.statusCode {
                    let apiClientStatus = APIClientStatus(statusCode)
                    switch apiClientStatus {
                    case .success:
                        switch API {
                        case .flushEvents:
                            completion(.success(true as! T)) // swiftlint:disable:this force_cast
                        default:
                            do {
                                let json = try JSONSerialization.jsonObject(with: data ?? Data(), options: [])
                                print(json)
                                let object = try JSONDecoder().decode(T.self, from: data ?? Data())
                                print(object)
                                completion(.success(object))
                            } catch {
                                completion(.failure(NSError(code: .DECODING_FAILED)))
                            }
                        }
                    default:
                        let errorCode = handleCustomError(data: data ?? Data())
                        completion(.failure(NSError(code: errorCode)))
                    }
                } else {
                    completion(.failure(NSError(code: .SERVER_ERROR)))
                }
            }
        })
        dataTask.resume()
    }
    
    static func handleCustomError(data: Data) -> RSErrorCode {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                return .SERVER_ERROR
            }
            print(json)
            if let message = json["message"], message == "Invalid write key" {
                return .WRONG_WRITE_KEY
            }
            return .SERVER_ERROR
        } catch {
            return .SERVER_ERROR
        }
    }
}
