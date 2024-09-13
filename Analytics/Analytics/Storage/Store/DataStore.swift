//
//  DataStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

public protocol DataStore {
    func retain<T: Codable>(value: T?, reference: String)
    func retrieve<T: Codable>(reference: String) -> T?
    func remove(reference: String)
}

