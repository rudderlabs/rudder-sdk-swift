//
//  ExtensionsTests.swift
//  RudderStackAnalyticsTests
//
//  Tests for dictionary/array extension methods including Date, URL, NSURL, and NSNull sanitization.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - Extensions Tests

@Suite("Extensions Tests")
class ExtensionsTests {

    // MARK: - Dictionary/Array Sanitization Test

    @Test("when dictionary contains Date/URL/NSURL at root and nested levels, then all are converted to strings")
    func testDictionarySanitizationWithComplexTypes() throws {
        // Input with all non-JSON types at various nesting levels
        let dict: [String: Any] = [
            // Root level
            "date": Date(timeIntervalSince1970: 631152000),
            "url": URL(string: "https://example.com")!,
            "nsurl": NSURL(string: "https://nsurl.com")!,
            "nsnull": NSNull(),

            // Nested dictionary
            "nested": [
                "nestedDate": Date(timeIntervalSince1970: 0),
                "nestedUrl": URL(string: "https://nested.com")!
            ] as [String: Any],

            // Array of mixed types
            "array": [
                Date(timeIntervalSince1970: 946684800),
                URL(string: "https://array.com")!
            ] as [Any]
        ]

        // Test objCSanitized
        let sanitized = dict.objCSanitized
        
        #expect(sanitized["date"] as? String == "1990-01-01T00:00:00.000Z")
        #expect(sanitized["url"] as? String == "https://example.com")
        #expect(sanitized["nsurl"] as? String == "https://nsurl.com")
        #expect(sanitized["nsnull"] == nil || sanitized["nsnull"] is NSNull)

        let nested = sanitized["nested"] as? [String: Any]
        #expect(nested?["nestedDate"] is String)
        #expect(nested?["nestedUrl"] is String)

        let array = sanitized["array"] as? [Any]
        #expect(array?[0] is String)
        #expect(array?[1] is String)

        // Test jsonString doesn't crash and contains expected values
        // Note: JSON escapes forward slashes, so we check for escaped or unescaped versions
        let jsonString = dict.jsonString
        
        #expect(jsonString != nil)
        #expect(jsonString!.contains("1990-01-01"))
        #expect(jsonString!.contains("example.com"))

        // Test rawDictionary via AnyCodable
        let codableDict: [String: AnyCodable] = [
            "date": AnyCodable(Date(timeIntervalSince1970: 0)),
            "url": AnyCodable(URL(string: "https://raw.com")!)
        ]
        let raw = codableDict.rawDictionary
        #expect(raw["date"] is String)
        #expect(raw["url"] is String)
    }
}
