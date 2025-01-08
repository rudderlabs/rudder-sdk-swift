//
//  DefaultsStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/09/24.
//

import Foundation
// MARK: - KeyValueStore
/**
 This class is designed to store and retrieve values using a custom UserDefaults object.
 */
final class KeyValueStore {
    private let writeKey: String
    private let userDefaults: UserDefaults?
    
    public init(writeKey: String) {
        self.writeKey = writeKey
        self.userDefaults = UserDefaults.rudder(self.writeKey)
    }
}

/**
 Basic operations for storing, retrieving, and deleting values.
 */
extension KeyValueStore {
    public func save<T: Codable>(value: T?, reference key: String) {
        if self.isPrimitiveType(value) {
            self.userDefaults?.set(value, forKey: key)
        } else {
            guard let encodedData = try? JSONEncoder().encode(value) else { return }
            self.userDefaults?.set(encodedData, forKey: key)
        }
        self.userDefaults?.synchronize()
    }
    
    public func read<T: Codable>(reference key: String) -> T? {
        var result: T? = nil
        let rawValue = self.userDefaults?.object(forKey: key)
        if let rawData = rawValue as? Data {
            guard let decodedValue = try? JSONDecoder().decode(T.self, from: rawData) else { return nil }
            result = decodedValue
        } else {
            result = rawValue as? T 
        }
        return result
    }
    
    public func delete(reference key: String) {
        self.userDefaults?.removeObject(forKey: key)
        self.userDefaults?.synchronize()
    }
}

/**
 Function to determine whether the received value is a primitive data type.
 */
extension KeyValueStore {
    private func isPrimitiveType<T: Codable>(_ value: T?) -> Bool {
        guard let value = value else { return true } //Since nil is also a primitive, & can be set to UserDefaults..
        
        return switch value {
        case is Int, is Double, is Float, is NSNumber, is Bool, is String, is Character:
            true
        default:
            false
        }
    }
}
