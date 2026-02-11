//
//  KeyValueStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/10/25.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

// MARK: - KeyValueStore Unit Tests
@Suite("KeyValueStore Unit Tests")
class KeyValueStoreTests {
    
    private var store: MockKeyValueStorage
    
    init() {
        store = MockKeyValueStorage()
    }
    
    deinit {
        // Clean up all stored values after each test class execution
        store.removeAll()
    }
    
    @Test(
        "when storing and reading various types, then all values are persisted correctly",
        arguments: [
            // MARK: Primitive Type Storage Tests
            ("string_key", TestValueWrapper.string("test_string_value")),
            ("int_key", TestValueWrapper.integer(42)),
            ("double_key", TestValueWrapper.double(3.14159)),
            ("float_key", TestValueWrapper.float(2.718)),
            ("bool_key", TestValueWrapper.boolean(true)),
            // "Character" test case (stored as String in original)
            ("char_key", TestValueWrapper.string("A")),
            
            // MARK: Array Type Storage Tests
            ("string_array_key", TestValueWrapper.stringArray(["apple", "banana", "cherry"])),
            ("int_array_key", TestValueWrapper.intArray([1, 2, 3, 4, 5])),
            ("bool_array_key", TestValueWrapper.booleanArray([true, false, true])),
            
            // MARK: Complex Type Storage Tests
            ("codable_key", TestValueWrapper.simpleObject(SimpleTestObject(id: "123", name: "Test Object", count: 42, isActive: true))),
            ("dict_key", TestValueWrapper.stringDictionary(["name": "John", "city": "New York", "country": "USA"])),
            ("nested_codable_key", TestValueWrapper.nestedObject(Person(
                name: "Alice",
                age: 30,
                address: Address(street: "123 Main St", city: "Anytown", zipCode: "12345"),
                hobbies: ["reading", "swimming"]
            )))
        ]
    )
    func testAllStorageTypes(key: String, value: TestValueWrapper) async {
        switch value {
        case .string(let stringValue):
            store.write(value: stringValue, key: key)
            let retrieved: String? = store.read(key: key)
            #expect(retrieved == stringValue, "String value failed to persist")
            
        case .integer(let intValue):
            store.write(value: intValue, key: key)
            let retrieved: Int? = store.read(key: key)
            #expect(retrieved == intValue, "Int value failed to persist")
            
        case .double(let doubleValue):
            store.write(value: doubleValue, key: key)
            let retrieved: Double? = store.read(key: key)
            #expect(retrieved == doubleValue, "Double value failed to persist")
            
        case .float(let floatValue):
            store.write(value: floatValue, key: key)
            let retrieved: Float? = store.read(key: key)
            #expect(retrieved == floatValue, "Float value failed to persist")
            
        case .boolean(let boolValue):
            store.write(value: boolValue, key: key)
            let retrieved: Bool? = store.read(key: key)
            #expect(retrieved == boolValue, "Bool value failed to persist")
            
        case .stringArray(let arrayValue):
            store.write(value: arrayValue, key: key)
            let retrieved: [String]? = store.read(key: key)
            #expect(retrieved == arrayValue, "String Array value failed to persist")
            
        case .intArray(let arrayValue):
            store.write(value: arrayValue, key: key)
            let retrieved: [Int]? = store.read(key: key)
            #expect(retrieved == arrayValue, "Int Array value failed to persist")
            
        case .booleanArray(let arrayValue):
            store.write(value: arrayValue, key: key)
            let retrieved: [Bool]? = store.read(key: key)
            #expect(retrieved == arrayValue, "Bool Array value failed to persist")
            
        case .stringDictionary(let dictValue):
            store.write(value: dictValue, key: key)
            let retrieved: [String: String]? = store.read(key: key)
            #expect(retrieved == dictValue, "Dictionary value failed to persist")
            
        case .simpleObject(let objectValue):
            store.write(value: objectValue, key: key)
            let retrieved: SimpleTestObject? = store.read(key: key)
            #expect(retrieved == objectValue, "Simple Object failed to persist")
            
        case .nestedObject(let objectValue):
            store.write(value: objectValue, key: key)
            let retrieved: Person? = store.read(key: key)
            #expect(retrieved == objectValue, "Nested Object failed to persist")
        }
    }
    
    // MARK: - Nil Value Storage Tests
    
    @Test("when removing a key, then reading returns nil")
    func testNilValueStorage() async {
        let key = "nil_key"
        
        store.write(value: "temporary", key: key)
        store.remove(key: key)
        let retrievedValue: String? = store.read(key: key)
        
        #expect(retrievedValue == nil)
    }
    
    // MARK: - Read Operations Tests
    
    @Test("when reading non-existent key, then nil is returned")
    func testReadNonExistentKey() async {
        let nonExistentKey = "non_existent_key"
        let retrievedValue: String? = store.read(key: nonExistentKey)
        
        #expect(retrievedValue == nil)
    }
    
    @Test("when reading with wrong type, then nil is returned")
    func testReadWithWrongType() async {
        let key = "wrong_type_key"
        let stringValue = "test_string"
        
        // Store as string
        store.write(value: stringValue, key: key)
        
        // Try to read as integer
        let retrievedValue: Int? = store.read(key: key)
        #expect(retrievedValue == nil)
    }
    
    // MARK: - Delete Operations Tests
    
    @Test("given stored value, when deleting key, then value is removed")
    func testDeleteStoredValue() async {
        let key = "delete_test_key"
        let value = "value_to_delete"
        
        // Store value
        store.write(value: value, key: key)
        var retrievedValue: String? = store.read(key: key)
        #expect(retrievedValue == value)
        
        // Delete value
        store.remove(key: key)
        retrievedValue = store.read(key: key)
        #expect(retrievedValue == nil)
    }
    
    @Test("when deleting non-existent key, then no error occurs")
    func testDeleteNonExistentKey() async {
        let nonExistentKey = "non_existent_delete_key"
        
        // This should not crash or throw
        store.remove(key: nonExistentKey)
        
        // Verify still nil
        let retrievedValue: String? = store.read(key: nonExistentKey)
        #expect(retrievedValue == nil)
    }
    
    // MARK: - RemoveAll Operations Tests
    
    @Test("given multiple stored values, when removing all, then all values are cleared")
    func testRemoveAllStoredValues() async {
        // Store multiple values of different types
        store.write(value: "value1", key: "key1")
        store.write(value: 42, key: "key2")
        store.write(value: true, key: "key3")
        store.write(value: 3.14, key: "key4")
        
        // Remove all
        store.removeAll()
        
        // Verify all values are removed
        let clearedValue1: String? = store.read(key: "key1")
        let clearedValue2: Int? = store.read(key: "key2")
        let clearedValue3: Bool? = store.read(key: "key3")
        let clearedValue4: Double? = store.read(key: "key4")
        
        #expect(clearedValue1 == nil)
        #expect(clearedValue2 == nil)
        #expect(clearedValue3 == nil)
        #expect(clearedValue4 == nil)
    }
    
    // MARK: - Key Isolation Tests
    
    @Test("given multiple storage instances, when storing values, then values are isolated")
    func testWriteKeyIsolation() async {
        let store1 = MockKeyValueStorage()
        let store2 = MockKeyValueStorage()
        
        let key = "shared_key"
        let value1 = "store1_value"
        let value2 = "store2_value"
        
        // Store different values in both stores with same key
        store1.write(value: value1, key: key)
        store2.write(value: value2, key: key)
        
        // Verify isolation - each store should return its own value
        let retrievedValue1: String? = store1.read(key: key)
        let retrievedValue2: String? = store2.read(key: key)
        
        #expect(retrievedValue1 == value1)
        #expect(retrievedValue2 == value2)
        #expect(retrievedValue1 != retrievedValue2)
        
        // Clean up
        store1.removeAll()
        store2.removeAll()
    }
    
    // MARK: - Update/Overwrite Tests
    
    @Test("given stored value, when storing new value with same key, then value is updated")
    func testValueUpdate() async {
        let key = "update_test_key"
        let originalValue = "original_value"
        let updatedValue = "updated_value"
        
        // Store original value
        store.write(value: originalValue, key: key)
        let retrievedOriginal: String? = store.read(key: key)
        #expect(retrievedOriginal == originalValue)
        
        // Update value
        store.write(value: updatedValue, key: key)
        let retrievedUpdated: String? = store.read(key: key)
        #expect(retrievedUpdated == updatedValue)
        #expect(retrievedUpdated != originalValue)
    }
    
    @Test("given stored value, when storing different type with same key, then type is updated")
    func testTypeUpdate() async {
        let key = "type_update_key"
        let stringValue = "123"
        let intValue = 456
        
        // Store string value
        store.write(value: stringValue, key: key)
        let retrievedString: String? = store.read(key: key)
        #expect(retrievedString == stringValue)
        
        // Update with integer value
        store.write(value: intValue, key: key)
        let retrievedInt: Int? = store.read(key: key)
        #expect(retrievedInt == intValue)
        
        // Original string should no longer be accessible
        let retrievedStringAfterUpdate: String? = store.read(key: key)
        #expect(retrievedStringAfterUpdate == nil)
    }
    
    // MARK: - Special Characters and Edge Cases Tests
    
    @Test("when storing values with special character keys, then values are persisted correctly")
    func testSpecialCharacterKeys() async {
        let specialKeys = [
            "key-with-dashes",
            "key_with_underscores",
            "key.with.dots",
            "key with spaces",
            "key@with#symbols$",
            "キー", // Japanese characters
            "🔑📦" // Emoji
        ]
        
        for (index, key) in specialKeys.enumerated() {
            let value = "value_\(index)"
            store.write(value: value, key: key)
            let retrievedValue: String? = store.read(key: key)
            #expect(retrievedValue == value)
            store.remove(key: key)
        }
    }
    
    @Test("when storing empty string values, then empty strings are handled correctly")
    func testEmptyStringStorage() async {
        let key = "empty_string_key"
        let emptyValue = ""
        
        store.write(value: emptyValue, key: key)
        let retrievedValue: String? = store.read(key: key)
        
        #expect(retrievedValue == emptyValue)
        #expect(retrievedValue != nil) // Empty string is different from nil
    }
    
    @Test("when storing large string values, then large strings are handled correctly")
    func testLargeStringStorage() async {
        let key = "large_string_key"
        let largeValue = String(repeating: "A", count: 10000) // 10KB string
        
        store.write(value: largeValue, key: key)
        let retrievedValue: String? = store.read(key: key)
        
        #expect(retrievedValue == largeValue)
        #expect(retrievedValue?.count == 10000)
    }
    
    // MARK: - JSON Encoding/Decoding Edge Cases Tests
    
    @Test("when storing object with invalid JSON characters, then object is handled correctly")
    func testInvalidJSONCharacters() async {
        struct TestObjectWithSpecialChars: Codable, Equatable {
            let text: String
            let unicode: String
            let quotes: String
        }
        
        let key = "special_chars_key"
        let value = TestObjectWithSpecialChars(
            text: "Text with \"quotes\" and \n newlines",
            unicode: "Unicode: 🚀 café naïve",
            quotes: "Say \"hello\" to 'world'"
        )
        
        store.write(value: value, key: key)
        let retrievedValue: TestObjectWithSpecialChars? = store.read(key: key)
        
        #expect(retrievedValue == value)
    }
}

// For testCodableObjectStorage
struct SimpleTestObject: Codable, Equatable {
    let id: String
    let name: String
    let count: Int
    let isActive: Bool
}

// For testNestedCodableObjectStorage
struct Address: Codable, Equatable {
    let street: String
    let city: String
    let zipCode: String
}

struct Person: Codable, Equatable {
    let name: String
    let age: Int
    let address: Address
    let hobbies: [String]
}

// This enum provides a single type that can hold all the different value types.
enum TestValueWrapper: Equatable {
    // Primitive types
    case string(String)
    case integer(Int)
    case double(Double)
    case float(Float)
    case boolean(Bool)
    // Collection types
    case stringArray([String])
    case intArray([Int])
    case booleanArray([Bool])
    case stringDictionary([String: String])
    // Codable objects
    case simpleObject(SimpleTestObject)
    case nestedObject(Person)
    
    // Helper to get the type (for logging/identification if needed)
    var typeName: String {
        switch self {
        case .string: return "String"
        case .integer: return "Int"
        case .double: return "Double"
        case .float: return "Float"
        case .boolean: return "Bool"
        case .stringArray: return "[String]"
        case .intArray: return "[Int]"
        case .booleanArray: return "[Bool]"
        case .stringDictionary: return "[String: String]"
        case .simpleObject: return "SimpleTestObject"
        case .nestedObject: return "Person"
        }
    }
}
