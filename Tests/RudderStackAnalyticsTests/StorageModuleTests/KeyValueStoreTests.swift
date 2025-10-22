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
    
    private let testWriteKey = "test-keyvalue-store-key-\(String.randomUUIDString)"
    private var store: KeyValueStore
    
    init() {
        store = KeyValueStore(writeKey: testWriteKey)
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
            store.save(value: stringValue, reference: key)
            let retrieved: String? = store.read(reference: key)
            #expect(retrieved == stringValue, "String value failed to persist")
            
        case .integer(let intValue):
            store.save(value: intValue, reference: key)
            let retrieved: Int? = store.read(reference: key)
            #expect(retrieved == intValue, "Int value failed to persist")
            
        case .double(let doubleValue):
            store.save(value: doubleValue, reference: key)
            let retrieved: Double? = store.read(reference: key)
            #expect(retrieved == doubleValue, "Double value failed to persist")

        case .float(let floatValue):
            store.save(value: floatValue, reference: key)
            let retrieved: Float? = store.read(reference: key)
            #expect(retrieved == floatValue, "Float value failed to persist")
            
        case .boolean(let boolValue):
            store.save(value: boolValue, reference: key)
            let retrieved: Bool? = store.read(reference: key)
            #expect(retrieved == boolValue, "Bool value failed to persist")
            
        case .stringArray(let arrayValue):
            store.save(value: arrayValue, reference: key)
            let retrieved: [String]? = store.read(reference: key)
            #expect(retrieved == arrayValue, "String Array value failed to persist")
            
        case .intArray(let arrayValue):
            store.save(value: arrayValue, reference: key)
            let retrieved: [Int]? = store.read(reference: key)
            #expect(retrieved == arrayValue, "Int Array value failed to persist")
            
        case .booleanArray(let arrayValue):
            store.save(value: arrayValue, reference: key)
            let retrieved: [Bool]? = store.read(reference: key)
            #expect(retrieved == arrayValue, "Bool Array value failed to persist")
            
        case .stringDictionary(let dictValue):
            store.save(value: dictValue, reference: key)
            let retrieved: [String: String]? = store.read(reference: key)
            #expect(retrieved == dictValue, "Dictionary value failed to persist")

        case .simpleObject(let objectValue):
            store.save(value: objectValue, reference: key)
            let retrieved: SimpleTestObject? = store.read(reference: key)
            #expect(retrieved == objectValue, "Simple Object failed to persist")
            
        case .nestedObject(let objectValue):
            store.save(value: objectValue, reference: key)
            let retrieved: Person? = store.read(reference: key)
            #expect(retrieved == objectValue, "Nested Object failed to persist")
        }
    }

    // MARK: - Nil Value Storage Tests
    
    @Test("when storing nil value, then nil is handled correctly")
    func testNilValueStorage() async {
        let key = "nil_key"
        let value: String? = nil
        
        store.save(value: value, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == nil)
    }
    
    // MARK: - Read Operations Tests
    
    @Test("when reading non-existent key, then nil is returned")
    func testReadNonExistentKey() async {
        let nonExistentKey = "non_existent_key"
        let retrievedValue: String? = store.read(reference: nonExistentKey)
        
        #expect(retrievedValue == nil)
    }
    
    @Test("when reading with wrong type, then nil is returned")
    func testReadWithWrongType() async {
        let key = "wrong_type_key"
        let stringValue = "test_string"
        
        // Store as string
        store.save(value: stringValue, reference: key)
        
        // Try to read as integer
        let retrievedValue: Int? = store.read(reference: key)
        #expect(retrievedValue == nil)
    }
    
    // MARK: - Delete Operations Tests
    
    @Test("given KeyValueStore with stored value, when deleting key, then value is removed")
    func testDeleteStoredValue() async {
        let key = "delete_test_key"
        let value = "value_to_delete"
        
        // Store value
        store.save(value: value, reference: key)
        var retrievedValue: String? = store.read(reference: key)
        #expect(retrievedValue == value)
        
        // Delete value
        store.delete(reference: key)
        retrievedValue = store.read(reference: key)
        #expect(retrievedValue == nil)
    }
    
    @Test("when deleting non-existent key, then no error occurs")
    func testDeleteNonExistentKey() async {
        let nonExistentKey = "non_existent_delete_key"
        
        // This should not crash or throw
        store.delete(reference: nonExistentKey)
        
        // Verify still nil
        let retrievedValue: String? = store.read(reference: nonExistentKey)
        #expect(retrievedValue == nil)
    }
    
    // MARK: - RemoveAll Operations Tests
    
    @Test("given KeyValueStore with multiple stored values, when removing all, then all values are cleared")
    func testRemoveAllStoredValues() async {
        // Store multiple values of different types
        store.save(value: "value1", reference: "key1")
        store.save(value: 42, reference: "key2")
        store.save(value: true, reference: "key3")
        store.save(value: 3.14, reference: "key4")
        
        // Remove all
        store.removeAll()
        
        // Verify all values are removed
        let clearedValue1: String? = store.read(reference: "key1")
        let clearedValue2: Int? = store.read(reference: "key2")
        let clearedValue3: Bool? = store.read(reference: "key3")
        let clearedValue4: Double? = store.read(reference: "key4")
        
        #expect(clearedValue1 == nil)
        #expect(clearedValue2 == nil)
        #expect(clearedValue3 == nil)
        #expect(clearedValue4 == nil)
    }
    
    // MARK: - Key Isolation Tests
    
    @Test("given multiple KeyValueStore instances with different writeKeys, when storing values, then values are isolated")
    func testWriteKeyIsolation() async {
        let writeKey1 = "isolation_test_key_1"
        let writeKey2 = "isolation_test_key_2"
        let store1 = KeyValueStore(writeKey: writeKey1)
        let store2 = KeyValueStore(writeKey: writeKey2)
        
        let key = "shared_key"
        let value1 = "store1_value"
        let value2 = "store2_value"
        
        // Store different values in both stores with same key
        store1.save(value: value1, reference: key)
        store2.save(value: value2, reference: key)
        
        // Verify isolation - each store should return its own value
        let retrievedValue1: String? = store1.read(reference: key)
        let retrievedValue2: String? = store2.read(reference: key)
        
        #expect(retrievedValue1 == value1)
        #expect(retrievedValue2 == value2)
        #expect(retrievedValue1 != retrievedValue2)
        
        // Clean up
        store1.removeAll()
        store2.removeAll()
    }
    
    // MARK: - Update/Overwrite Tests
    
    @Test("given KeyValueStore with stored value, when storing new value with same key, then value is updated")
    func testValueUpdate() async {
        let key = "update_test_key"
        let originalValue = "original_value"
        let updatedValue = "updated_value"
        
        // Store original value
        store.save(value: originalValue, reference: key)
        let retrievedOriginal: String? = store.read(reference: key)
        #expect(retrievedOriginal == originalValue)
        
        // Update value
        store.save(value: updatedValue, reference: key)
        let retrievedUpdated: String? = store.read(reference: key)
        #expect(retrievedUpdated == updatedValue)
        #expect(retrievedUpdated != originalValue)
    }
    
    @Test("given KeyValueStore with stored value, when storing different type with same key, then type is updated")
    func testTypeUpdate() async {
        let key = "type_update_key"
        let stringValue = "123"
        let intValue = 456
        
        // Store string value
        store.save(value: stringValue, reference: key)
        let retrievedString: String? = store.read(reference: key)
        #expect(retrievedString == stringValue)
        
        // Update with integer value
        store.save(value: intValue, reference: key)
        let retrievedInt: Int? = store.read(reference: key)
        #expect(retrievedInt == intValue)
        
        // Original string should no longer be accessible
        let retrievedStringAfterUpdate: String? = store.read(reference: key)
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
            store.save(value: value, reference: key)
            let retrievedValue: String? = store.read(reference: key)
            #expect(retrievedValue == value)
            store.delete(reference: key)
        }
    }
    
    @Test("when storing empty string values, then empty strings are handled correctly")
    func testEmptyStringStorage() async {
        let key = "empty_string_key"
        let emptyValue = ""
        
        store.save(value: emptyValue, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == emptyValue)
        #expect(retrievedValue != nil) // Empty string is different from nil
    }
    
    @Test("when storing large string values, then large strings are handled correctly")
    func testLargeStringStorage() async {
        let key = "large_string_key"
        let largeValue = String(repeating: "A", count: 10000) // 10KB string
        
        store.save(value: largeValue, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
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
        
        store.save(value: value, reference: key)
        let retrievedValue: TestObjectWithSpecialChars? = store.read(reference: key)
        
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
