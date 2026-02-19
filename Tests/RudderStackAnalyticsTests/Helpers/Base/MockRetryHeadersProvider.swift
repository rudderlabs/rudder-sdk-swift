//
//  MockRetryHeadersProvider.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/02/26.
//

import Foundation
@testable import RudderStackAnalytics

final class MockRetryHeadersProvider: RetryHeadersProvider {
      var prepareHeadersCallCount = 0
      var recordFailureCallCount = 0
      var clearCallCount = 0

      var lastPrepareHeadersBatchId: Int?
      var lastRecordFailureBatchId: Int?
      var lastRecordFailureError: RetryableEventUploadError?

      var headersToReturn: [String: String] = [:]

      func prepareHeaders(batchId: Int, currentTimestampInMillis: UInt64) -> [String: String] {
          prepareHeadersCallCount += 1
          lastPrepareHeadersBatchId = batchId
          return headersToReturn
      }

      func recordFailure(batchId: Int, timestampInMillis: UInt64, error: RetryableEventUploadError) {
          recordFailureCallCount += 1
          lastRecordFailureBatchId = batchId
          lastRecordFailureError = error
      }

      func clear() {
          clearCallCount += 1
      }
  }
