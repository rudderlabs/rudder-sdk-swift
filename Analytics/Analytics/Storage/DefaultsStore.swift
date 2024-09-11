//
//  DefaultsStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/09/24.
//

import Foundation

final class DefaultsStore {
    let writeKey: String
    let userDefaults: UserDefaults?
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.userDefaults = UserDefaults.rudder(self.writeKey)
    }
    
    func writeDefaults<T: Codable>(value: T?, key: String) {
        if self.isPrimitiveType(value) {
            self.userDefaults?.set(value, forKey: key)
        } else {
            guard let encodedData = try? JSONEncoder().encode(value) else { return }
            self.userDefaults?.set(encodedData, forKey: key)
        }
    }
    
    func readDefaults<T: Codable>(key: String) -> T? {
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
}

extension DefaultsStore {
    func isPrimitiveType<T: Codable>(_ value: T?) -> Bool {
        guard let value = value else { return true } //Since nil is also a primitive, & can be set to UserDefaults..
        
        return switch value {
        case is Int, is Double, is NSNumber, is Bool, is String:
            true
        default:
            false
        }
    }
}
