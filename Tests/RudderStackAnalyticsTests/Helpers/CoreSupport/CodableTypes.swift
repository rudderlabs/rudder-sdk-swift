//
//  CodableTypes.swift
//  RudderStackAnalyticsTests
//
//  Tests for AnyCodable encoding with NSNull, Date, URL, and NSURL types.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - AnyCodable Encoding Tests

@Suite("AnyCodable Encoding Tests")
class CodableTypesTests {

    // MARK: - AnyCodable Encoding Test

    @Test("when AnyCodable wraps NSNull/Date/URL/NSURL, then all encode to valid JSON")
    func testAnyCodableEncodingWithSpecialTypes() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes

        // Test NSNull encodes as JSON null
        let nullData = try encoder.encode(AnyCodable(NSNull()))
        #expect(String(data: nullData, encoding: .utf8) == "null")

        // Test Date encodes as ISO8601 string
        let dateData = try encoder.encode(AnyCodable(Date(timeIntervalSince1970: 631152000)))
        #expect(String(data: dateData, encoding: .utf8) == "\"1990-01-01T00:00:00.000Z\"")

        // Test URL encodes as string
        let urlData = try encoder.encode(AnyCodable(URL(string: "https://example.com/path")!))
        #expect(String(data: urlData, encoding: .utf8) == "\"https://example.com/path\"")

        // Test NSURL encodes as string
        let nsurlData = try encoder.encode(AnyCodable(NSURL(string: "https://nsurl.com")!))
        #expect(String(data: nsurlData, encoding: .utf8) == "\"https://nsurl.com\"")

        // Test complex dictionary with all types encodes successfully
        let complexDict: [String: Any] = [
            "null": NSNull(),
            "date": Date(timeIntervalSince1970: 0),
            "url": URL(string: "https://test.com")!,
            "string": "hello",
            "number": 42
        ]
        let complexData = try encoder.encode(AnyCodable(complexDict))
        let json = String(data: complexData, encoding: .utf8)!
        #expect(json.contains("\"null\":null"))
        #expect(json.contains("test.com"))
    }
}
