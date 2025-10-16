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
    
    private let testWriteKey = "test-keyvalue-store-key-123"
    private var store: KeyValueStore
    
    init() {
        store = KeyValueStore(writeKey: testWriteKey)
    }
    
    deinit {
        // Clean up all stored values after each test class execution
        store.removeAll()
    }
    
    // MARK: - Initialization Tests
    
    @Test("given writeKey, when initializing KeyValueStore, then store is created successfully")
    func testInitialization() async {
        let writeKey = "test-init-key"
        let keyValueStore = KeyValueStore(writeKey: writeKey)
        
        // Verify store can be used after initialization
        keyValueStore.save(value: "test", reference: "init_test")
        let result: String? = keyValueStore.read(reference: "init_test")
        #expect(result == "test")
    }
    
    // MARK: - Primitive Type Storage Tests
    
    @Test("given KeyValueStore, when storing and reading string value, then value is persisted correctly")
    func testStringStorage() async {
        let key = "string_key"
        let value = "test_string_value"
        
        store.save(value: value, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading integer value, then value is persisted correctly")
    func testIntegerStorage() async {
        let key = "int_key"
        let value = 42
        
        store.save(value: value, reference: key)
        let retrievedValue: Int? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading double value, then value is persisted correctly")
    func testDoubleStorage() async {
        let key = "double_key"
        let value = 3.14159
        
        store.save(value: value, reference: key)
        let retrievedValue: Double? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading float value, then value is persisted correctly")
    func testFloatStorage() async {
        let key = "float_key"
        let value: Float = 2.718
        
        store.save(value: value, reference: key)
        let retrievedValue: Float? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading boolean value, then value is persisted correctly")
    func testBooleanStorage() async {
        let key = "bool_key"
        let value = true
        
        store.save(value: value, reference: key)
        let retrievedValue: Bool? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading character value, then value is persisted correctly")
    func testCharacterStorage() async {
        let key = "char_key"
        let value = "A" // Store as String instead of Character since Character doesn't conform to Codable
        
        store.save(value: value, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    // MARK: - Array Type Storage Tests
    
    @Test("given KeyValueStore, when storing and reading string array, then array is persisted correctly")
    func testStringArrayStorage() async {
        let key = "string_array_key"
        let value = ["apple", "banana", "cherry"]
        
        store.save(value: value, reference: key)
        let retrievedValue: [String]? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading integer array, then array is persisted correctly")
    func testIntegerArrayStorage() async {
        let key = "int_array_key"
        let value = [1, 2, 3, 4, 5]
        
        store.save(value: value, reference: key)
        let retrievedValue: [Int]? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading boolean array, then array is persisted correctly")
    func testBooleanArrayStorage() async {
        let key = "bool_array_key"
        let value = [true, false, true]
        
        store.save(value: value, reference: key)
        let retrievedValue: [Bool]? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    // MARK: - Complex Type Storage Tests
    
    @Test("given KeyValueStore, when storing and reading codable object, then object is persisted correctly")
    func testCodableObjectStorage() async {
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let count: Int
            let isActive: Bool
        }
        
        let key = "codable_key"
        let value = TestObject(id: "123", name: "Test Object", count: 42, isActive: true)
        
        store.save(value: value, reference: key)
        let retrievedValue: TestObject? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading dictionary, then dictionary is persisted correctly")
    func testDictionaryStorage() async {
        let key = "dict_key"
        let value = ["name": "John", "city": "New York", "country": "USA"]
        
        store.save(value: value, reference: key)
        let retrievedValue: [String: String]? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given KeyValueStore, when storing and reading nested codable object, then object is persisted correctly")
    func testNestedCodableObjectStorage() async {
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
        
        let key = "nested_codable_key"
        let address = Address(street: "123 Main St", city: "Anytown", zipCode: "12345")
        let value = Person(name: "Alice", age: 30, address: address, hobbies: ["reading", "swimming"])
        
        store.save(value: value, reference: key)
        let retrievedValue: Person? = store.read(reference: key)
        
        #expect(retrievedValue == value)
    }
    
    // MARK: - Nil Value Storage Tests
    
    @Test("given KeyValueStore, when storing nil value, then nil is handled correctly")
    func testNilValueStorage() async {
        let key = "nil_key"
        let value: String? = nil
        
        store.save(value: value, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == nil)
    }
    
    // MARK: - Read Operations Tests
    
    @Test("given KeyValueStore, when reading non-existent key, then nil is returned")
    func testReadNonExistentKey() async {
        let nonExistentKey = "non_existent_key"
        let retrievedValue: String? = store.read(reference: nonExistentKey)
        
        #expect(retrievedValue == nil)
    }
    
    @Test("given KeyValueStore, when reading with wrong type, then nil is returned")
    func testReadWithWrongType() async {
        let key = "wrong_type_key"
        let stringValue = "test_string"
        
        // Store as string
        store.save(value: stringValue, reference: key)
        
        // Try to read as integer
        let retrievedValue: Int? = store.read(reference: key)
        
        #expect(retrievedValue == nil)
        
        // Verify original string value is still accessible
        let originalValue: String? = store.read(reference: key)
        #expect(originalValue == stringValue)
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
    
    @Test("given KeyValueStore, when deleting non-existent key, then no error occurs")
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
        
        // Verify values are stored
        let value1: String? = store.read(reference: "key1")
        let value2: Int? = store.read(reference: "key2")
        let value3: Bool? = store.read(reference: "key3")
        let value4: Double? = store.read(reference: "key4")
        
        #expect(value1 == "value1")
        #expect(value2 == 42)
        #expect(value3 == true)
        #expect(value4 == 3.14)
        
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
    
    @Test("given KeyValueStore, when storing values with special character keys, then values are persisted correctly")
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
    
    @Test("given KeyValueStore, when storing empty string values, then empty strings are handled correctly")
    func testEmptyStringStorage() async {
        let key = "empty_string_key"
        let emptyValue = ""
        
        store.save(value: emptyValue, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == emptyValue)
        #expect(retrievedValue != nil) // Empty string is different from nil
    }
    
    @Test("given KeyValueStore, when storing large string values, then large strings are handled correctly")
    func testLargeStringStorage() async {
        let key = "large_string_key"
        let largeValue = String(repeating: "A", count: 10000) // 10KB string
        
        store.save(value: largeValue, reference: key)
        let retrievedValue: String? = store.read(reference: key)
        
        #expect(retrievedValue == largeValue)
        #expect(retrievedValue?.count == 10000)
    }
    
    // MARK: - JSON Encoding/Decoding Edge Cases Tests
    
    @Test("given KeyValueStore, when storing object with invalid JSON characters, then object is handled correctly")
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
