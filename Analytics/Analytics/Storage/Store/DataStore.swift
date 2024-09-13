//
//  DataStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

public protocol DataStore {
    func retain<T: Codable>(value: T?, key: String)
    func retain<T: Codable>(value: T?)
    func retrieve<T: Codable>(key: String) -> T?
    func retrieve<T: Codable>(filePath: String) -> T?
    func remove(key: String)
    func remove(filePath: String)
}

extension DataStore {
    func retain<T: Codable>(value: T?, key: String) {}
    func retain<T: Codable>(value: T?) {}
    func remove(key: String) {}
    func remove(filePath: String) {}
    func retrieve<T: Codable>(key: String) -> T? { return nil }
    func retrieve<T: Codable>(filePath: String) -> T? { return nil }
}
