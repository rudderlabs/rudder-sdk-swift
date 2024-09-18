//
//  CodableTypes.swift
//  Analytics
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Foundation

// MARK: - CodableDictionary

public struct CodableDictionary: Codable {
    @AutoCodable public var data: [String: AnyCodable]
    
    public init?(_ input: [String: Any]?) {
        guard let input = input else { return nil }
        self.data = input.mapValues { AnyCodable($0) }
    }
}

// MARK: - CodableArray

public struct CodableArray: Codable {
    @AutoCodable public var data: [AnyCodable]
    
    public init?(_ input: [Any]?) {
        guard let input = input else { return nil }
        self.data = input.map { AnyCodable($0) }
    }
}

// MARK: - AutoCodable

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

// MARK: - AnyCodable

public struct AnyCodable: Codable {
    let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let arrayValue = value as? [Any] {
            try container.encode(arrayValue.map { AnyCodable($0) })
        } else if let dictionaryValue = value as? [String: Any] {
            try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
