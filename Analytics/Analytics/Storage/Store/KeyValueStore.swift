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
    func save(value: Any?, reference key: String) {
        guard let value = value else {
            self.delete(reference: key)
            return
        }
        
        guard isSupportedType(value) else { return }
        
        if JSONSerialization.isValidJSONObject(value), let data = try? JSONSerialization.data(withJSONObject: value, options: []) {
            self.userDefaults?.set(data, forKey: key)
        } else {
            self.userDefaults?.set(value, forKey: key)
        }
        self.userDefaults?.synchronize()
    }
    
    /**
     Reads and returns a value from `UserDefaults`.
     */
    func read(reference key: String) -> Any? {
        guard let rawValue = self.userDefaults?.object(forKey: key) else { return nil }
        
        if let data = rawValue as? Data {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                return jsonObject
            } catch {
                // If decoding fails, return the raw data
                return data
            }
        }
        return rawValue
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
    private func isSupportedType(_ value: Any) -> Bool {
        switch value {
        case is Int, is Double, is Float, is Bool, is String, is Character, is Date, is Data, is URL, is NSNumber:
            return true
        case let array as [Any]:
            return array.allSatisfy { isSupportedType($0) }
        case let dict as [String: Any]:
            return dict.values.allSatisfy { isSupportedType($0) }
        default:
            return false
        }
    }
}
