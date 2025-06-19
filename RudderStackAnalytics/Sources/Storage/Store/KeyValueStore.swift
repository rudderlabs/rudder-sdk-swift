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
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.userDefaults = UserDefaults.rudder(self.writeKey)
    }
}

/**
 Basic operations for storing, retrieving, and deleting values.
 */
extension KeyValueStore {
    /**
     Saves a value to `UserDefaults` if it's supported.
     */
    func save<T: Codable>(value: T?, reference key: String) {
        if self.isPrimitiveType(value) {
            self.userDefaults?.set(value, forKey: key)
        } else {
            guard let encodedData = try? JSONEncoder().encode(value) else { return }
            self.userDefaults?.set(encodedData, forKey: key)
        }
        self.userDefaults?.synchronize()
    }
    
    /**
     Reads and returns a value from `UserDefaults`.
     */
    func read<T: Codable>(reference key: String) -> T? {
        var result: T?
        let rawValue = self.userDefaults?.object(forKey: key)
        if let rawData = rawValue as? Data {
            guard let decodedValue = try? JSONDecoder().decode(T.self, from: rawData) else { return nil }
            result = decodedValue
        } else {
            result = rawValue as? T
        }
        return result
    }
    
    /**
     Deletes a stored value for the given key.
     */
    func delete(reference key: String) {
        self.userDefaults?.removeObject(forKey: key)
        self.userDefaults?.synchronize()
    }
}

/**
 Function to determine whether the received value is is supported for storage.
 */
extension KeyValueStore {
    private func isPrimitiveType<T: Codable>(_ value: T?) -> Bool {
        guard let value = value else { return true } // Since nil is also a primitive, & can be set to UserDefaults..
        
        return switch value {
        case is Int, is Double, is Float, is NSNumber, is Bool, is String, is Character,
            is [Int], is [Double], is [Float], is [NSNumber], is [Bool], is [String], is [Character]:
            true
        default:
            false
        }
    }
}
