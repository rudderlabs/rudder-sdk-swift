//
//  RetryMetadataTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/02/26.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("RetryMetadata Tests")
struct RetryMetadataTests {

    private let sampleMetadata = RetryMetadata(
        batchId: "batch-123",
        attempt: 3,
        lastAttemptTimestampInMillis: 1700000000000,
        reason: "server-502"
    )

    // MARK: - Serialization Tests

    @Test("given valid metadata, when converting to JSON, then returns non-nil JSON string")
    func testToJsonReturnsValidJson() {
        let json = sampleMetadata.toJson()

        #expect(json != nil)
        #expect(json?.contains("batch-123") == true)
        #expect(json?.contains("server-502") == true)
    }

    @Test("given valid JSON string, when parsing, then all fields are correctly decoded")
    func testFromJsonParsesCorrectly() {
        let json = """
        {"batchId":"batch-456","attempt":2,"lastAttemptTimestampInMillis":1700000005000,"reason":"client-timeout"}
        """

        let metadata = RetryMetadata.fromJson(json)

        #expect(metadata?.batchId == "batch-456")
        #expect(metadata?.attempt == 2)
        #expect(metadata?.lastAttemptTimestampInMillis == 1700000005000)
        #expect(metadata?.reason == "client-timeout")
    }

    @Test("given metadata, when round-tripping through JSON, then original equals decoded")
    func testRoundTrip() {
        guard let json = sampleMetadata.toJson() else {
            Issue.record("toJson() returned nil")
            return
        }

        let decoded = RetryMetadata.fromJson(json)

        #expect(decoded == sampleMetadata)
    }

    // MARK: - fromJson Failure Tests

    @Test("given invalid JSON string, when parsing, then returns nil")
    func testFromJsonWithInvalidJsonReturnsNil() {
        let result = RetryMetadata.fromJson("not valid json")

        #expect(result == nil)
    }

    @Test("given empty string, when parsing, then returns nil")
    func testFromJsonWithEmptyStringReturnsNil() {
        let result = RetryMetadata.fromJson("")

        #expect(result == nil)
    }

    @Test("given JSON with missing required fields, when parsing, then returns nil")
    func testFromJsonWithMissingFieldsReturnsNil() {
        let json = """
        {"batchId":"batch-789","attempt":1}
        """

        let result = RetryMetadata.fromJson(json)

        #expect(result == nil)
    }

    // MARK: - Retry Reason Mapping Tests

    @Test("given retryable error with status code, when getting retry reason, then returns server reason")
    func testRetryableWithStatusCodeReturnsServerReason() {
        #expect(RetryableEventUploadError.retryable(statusCode: 502).retryReason == "server-502")
    }

    @Test("given retryable error with nil status code, when getting retry reason, then returns client-network")
    func testRetryableWithNilStatusCodeReturnsClientNetwork() {
        #expect(RetryableEventUploadError.retryable(statusCode: nil).retryReason == "client-network")
    }

    @Test("given network unavailable error, when getting retry reason, then returns client-network")
    func testNetworkUnavailableReturnsClientNetwork() {
        #expect(RetryableEventUploadError.networkUnavailable.retryReason == "client-network")
    }

    @Test("given timeout error, when getting retry reason, then returns client-timeout")
    func testTimeoutReturnsClientTimeout() {
        #expect(RetryableEventUploadError.timeout.retryReason == "client-timeout")
    }

    @Test("given unknown error, when getting retry reason, then returns client-unknown")
    func testUnknownReturnsClientUnknown() {
        #expect(RetryableEventUploadError.unknown.retryReason == "client-unknown")
    }
}
