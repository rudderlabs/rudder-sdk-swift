//
//  CodableTypes.swift
//  Analytics
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Foundation

// MARK: - CodableCollection
/**
 A type that supports encoding and decoding collections of heterogeneous data.

 The `CodableCollection` struct is designed to handle both arrays and dictionaries with elements of varying types, enabling flexible encoding and decoding of complex data structures. This is particularly useful for handling dynamic JSON payloads.

 - Features:
   - Supports encoding and decoding of arrays and dictionaries.
   - Handles mixed data types through the use of `AnyCodable`.

 - Usage:
   Use the provided initializers to create instances with either an array or a dictionary. When encoding, the type of collection is preserved, and decoding automatically determines whether the collection is an array or a dictionary.
 */
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
/**
 A wrapper type to enable encoding and decoding of heterogeneous data.

 The `AnyCodable` struct encapsulates a value of any type, providing support for encoding and decoding into and from JSON. This makes it possible to handle dynamic and mixed data types in scenarios where the structure of the data isn't known at compile time.

 - Features:
   - Supports a wide range of data types, including primitives, arrays, and dictionaries.
   - Handles encoding and decoding of custom types like `Date` and `CGFloat`.
   - Useful for dynamic JSON serialization and deserialization.

 - Usage:
   Initialize with any value and encode or decode it as needed. When decoding, it determines the type dynamically based on the JSON structure.

 - Note:
   Unsupported types during encoding or decoding will throw an error.
 */
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let intValue = try? container.decode(UInt64.self) {
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
        } else if let intValue = value as? UInt64 {
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
