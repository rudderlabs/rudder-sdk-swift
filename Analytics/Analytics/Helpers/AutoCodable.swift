//
//  AutoCodable.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

// The class is currently not in use but may be needed in the future.
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

public enum CodableValue: Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)
    case array([CodableValue])
    case dictionary([String: CodableValue])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode([CodableValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: CodableValue].self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.typeMismatch(CodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported value"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}
