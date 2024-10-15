//
//  PropertyWrappers.swift
//  Analytics
//
//  Created by Satheesh Kannan on 19/09/24.
//

import Foundation

// MARK: - Synchronized
/**
 This `propertyWrapper` ensures that the property is `thread-safe`.
 */
@propertyWrapper
public final class Synchronized<T> {
    var value: T
    
    private var lock = pthread_rwlock_t()

    public init(wrappedValue value: T) {
        pthread_rwlock_init(&lock, nil)
        self.value = value
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    public var wrappedValue: T {
        get {
            pthread_rwlock_rdlock(&lock)
            defer { pthread_rwlock_unlock(&lock) }
            return value
        }
        set {
            pthread_rwlock_wrlock(&lock)
            value = newValue
            pthread_rwlock_unlock(&lock)
        }
    }

    // New modify method to perform compound operations atomically
    public func modify(_ block: (inout T) -> Void) {
        pthread_rwlock_wrlock(&lock)
        block(&value)
        pthread_rwlock_unlock(&lock)
    }
}

// MARK: - AutoCodable
/**
 This `propertyWrapper` converts the property as a `Codable` one.
 */
@propertyWrapper
public struct AutoCodable<T: Codable>: Codable {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        if let codableValue = wrappedValue as? AnyCodable {
            try codableValue.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encode(wrappedValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if T.self == AnyCodable.self {
            // Handle CodableValue specifically
            let value = try AnyCodable(from: decoder)
            self.wrappedValue = value as! T
        } else {
            // Handle generic Codable types
            self.wrappedValue = try container.decode(T.self)
        }
    }
}

// MARK: - AutoEquatable
/**
 This `propertyWrapper` converts the property as a `Equatable` one.
 */
@propertyWrapper
public struct AutoEquatable<T: Equatable>: Equatable {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public static func == (lhs: AutoEquatable<T>, rhs: AutoEquatable<T>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}
