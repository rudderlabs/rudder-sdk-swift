//
//  PrimaryRetryHeadersProviderTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/02/26.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("PrimaryRetryHeadersProvider Tests")
struct PrimaryRetryHeadersProviderTests {
    
    private let mockStorage = MockKeyValueStorage()
    private let provider: PrimaryRetryHeadersProvider
    
    init() {
        provider = PrimaryRetryHeadersProvider(storage: mockStorage)
    }
    
    // MARK: - prepareHeaders Tests
    
    @Test("given no prior failure, when preparing headers, then returns empty dictionary")
    func testPrepareHeadersReturnsEmptyWhenNoMetadata() {
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1000)
        
        #expect(headers.isEmpty)
    }
    
    @Test("given recorded failure, when preparing headers, then returns all three retry headers")
    func testRecordFailureThenPrepareHeadersReturnsHeaders() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .retryable(statusCode: 502))
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1500)
        
        #expect(headers.count == 3)
        #expect(headers[RetryHeaderKeys.rsaRetryAttempt] != nil)
        #expect(headers[RetryHeaderKeys.rsaSinceLastAttempt] != nil)
        #expect(headers[RetryHeaderKeys.rsaRetryReason] != nil)
    }
    
    // MARK: - Attempt Tracking Tests
    
    @Test("given first failure, when preparing headers, then attempt is 1")
    func testFirstFailureRecordsAttempt1() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .retryable(statusCode: 502))
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1500)
        
        #expect(headers[RetryHeaderKeys.rsaRetryAttempt] == "1")
    }
    
    @Test("given two failures, when preparing headers, then attempt is 2")
    func testSecondFailureIncrementsAttemptTo2() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .retryable(statusCode: 502))
        provider.recordFailure(batchId: 1, timestampInMillis: 2000, error: .retryable(statusCode: 502))
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 2500)
        
        #expect(headers[RetryHeaderKeys.rsaRetryAttempt] == "2")
    }
    
    // MARK: - Since Last Attempt Tests
    
    @Test("given recorded failure, when preparing headers with later timestamp, then calculates elapsed time")
    func testSinceLastAttemptCalculation() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .timeout)
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1500)
        
        #expect(headers[RetryHeaderKeys.rsaSinceLastAttempt] == "500")
    }
    
    @Test("given recorded failure, when preparing headers with earlier timestamp (clock skew), then clamps to zero")
    func testSinceLastAttemptClampsToZeroOnClockSkew() {
        provider.recordFailure(batchId: 1, timestampInMillis: 2000, error: .timeout)
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1000)
        
        #expect(headers[RetryHeaderKeys.rsaSinceLastAttempt] == "0")
    }
    
    // MARK: - Retry Reason Tests
    
    @Test("given failure with specific error, when preparing headers, then reason matches error")
    func testRetryReasonIsRecorded() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .timeout)
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1500)
        
        #expect(headers[RetryHeaderKeys.rsaRetryReason] == "client-timeout")
    }
    
    @Test("given multiple failures with different errors, when preparing headers, then reason reflects latest error")
    func testRetryReasonUpdatesOnSubsequentFailure() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .timeout)
        provider.recordFailure(batchId: 1, timestampInMillis: 2000, error: .networkUnavailable)
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 2500)
        
        #expect(headers[RetryHeaderKeys.rsaRetryReason] == "client-network")
    }
    
    // MARK: - Batch ID Mismatch Tests
    
    @Test("given metadata for different batch, when preparing headers, then returns empty dictionary")
    func testBatchIdMismatchReturnsEmptyHeaders() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .retryable(statusCode: 502))
        
        let headers = provider.prepareHeaders(batchId: 2, currentTimestampInMillis: 1500)
        
        #expect(headers.isEmpty)
    }
    
    @Test("given metadata for different batch, when preparing headers with original batch, then still returns headers")
    func testBatchIdMismatchDoesNotClearMetadata() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .retryable(statusCode: 502))
        
        // Mismatched batch returns empty
        let mismatchHeaders = provider.prepareHeaders(batchId: 2, currentTimestampInMillis: 1500)
        #expect(mismatchHeaders.isEmpty)
        
        // Original batch still returns headers
        let originalHeaders = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 2000)
        #expect(originalHeaders[RetryHeaderKeys.rsaRetryAttempt] == "1")
    }
    
    // MARK: - Clear Tests
    
    @Test("given recorded failure, when clearing, then subsequent prepareHeaders returns empty")
    func testClearRemovesMetadata() {
        provider.recordFailure(batchId: 1, timestampInMillis: 1000, error: .retryable(statusCode: 502))
        provider.clear()
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1500)
        
        #expect(headers.isEmpty)
    }
    
    @Test("given no metadata, when clearing, then does not crash")
    func testClearOnEmptyStorageDoesNotCrash() {
        provider.clear()
        
        let headers = provider.prepareHeaders(batchId: 1, currentTimestampInMillis: 1000)
        
        #expect(headers.isEmpty)
    }
}
