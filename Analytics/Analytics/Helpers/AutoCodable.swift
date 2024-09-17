//
//  AutoCodable.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

// The Property Wrapper is currently not in use but may be needed in the future.
@propertyWrapper
public struct AutoCodable<T: Codable>: Codable {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public func encode(to encoder: Encoder) throws {
        if let codableValue = wrappedValue as? CodableValue {
            try codableValue.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encode(wrappedValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if T.self == CodableValue.self {
            // Handle CodableValue specifically
            let value = try CodableValue(from: decoder)
            self.wrappedValue = value as! T
        } else {
            // Handle generic Codable types
            self.wrappedValue = try container.decode(T.self)
        }
    }
}

// MARK: - CodableValue
public enum CodableValue: Codable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case dictionary([String: CodableValue])
    case array([CodableValue])
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .stringValue) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self, forKey: .numberValue) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self, forKey: .booleanValue) {
            self = .boolean(value)
        } else if let value = try? container.decode([String: CodableValue].self, forKey: .dictionaryValue) {
            self = .dictionary(value)
        } else if let value = try? container.decode([CodableValue].self, forKey: .arrayValue) {
            self = .array(value)
        } else if container.contains(.nullValue) {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.stringValue, in: container, debugDescription: "Unsupported value type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let value):
            try container.encode(value, forKey: .stringValue)
        case .number(let value):
            try container.encode(value, forKey: .numberValue)
        case .boolean(let value):
            try container.encode(value, forKey: .booleanValue)
        case .dictionary(let value):
            try container.encode(value, forKey: .dictionaryValue)
        case .array(let value):
            try container.encode(value, forKey: .arrayValue)
        case .null:
            try container.encodeNil(forKey: .nullValue)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case stringValue
        case numberValue
        case booleanValue
        case dictionaryValue
        case arrayValue
        case nullValue
    }
}

