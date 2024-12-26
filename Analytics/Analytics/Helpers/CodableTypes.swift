//
//  CodableTypes.swift
//  Analytics
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Foundation

// MARK: - CodableCollection

public struct CodableCollection: Codable {
    public var array: [AnyCodable]?
    public var dictionary: [String: AnyCodable]?

    // Initializers for convenience
    public init?(array: [Any]?) {
        guard let array else { return nil }
        self.array = array.map { AnyCodable($0) }
        self.dictionary = nil
    }

    public init?(dictionary: [String: Any]?) {
        guard let dictionary else { return nil }
        self.dictionary = dictionary.mapValues { AnyCodable($0) }
        self.array = nil
    }

    // Encoding logic
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let array = array {
            try container.encode(array)
        } else if let dictionary = dictionary {
            try container.encode(dictionary)
        } else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "No values present in CodableCollection"))
        }
    }

    // Decoding logic
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let array = try? container.decode([AnyCodable].self) {
            self.array = array
            self.dictionary = nil
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.dictionary = dictionary
            self.array = nil
        } else {
            throw DecodingError.typeMismatch(CodableCollection.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected array or dictionary"))
        }
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let cgfloatValue = try? container.decode(CGFloat.self) {
            value = cgfloatValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = Date.date(from: stringValue) ?? stringValue
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
        } else if let cgfloatValue = value as? CGFloat {
            try container.encode(cgfloatValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let dateValue = value as? Date {
            try container.encode(dateValue.iso8601TimeStamp)
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
