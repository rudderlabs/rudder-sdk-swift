//
//  TrackEventE2ETest.swift
//  RudderStackAnalyticsTests
//
//  E2E test for the track API: validates the full pipeline from
//  analytics.track(...) through plugin chain, event queue, and flush
//  to the outgoing HTTP request captured at the network boundary.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("Track Event E2E Tests")
struct TrackEventE2ETests {

    @Test("track event delivers correct payload to data plane")
    func trackEventDeliversCorrectPayloadToDataPlane() async throws {
        // 1. Set up network interception
        let capture = RequestCapture()

        MockProvider.setupMockURLSession()
        MockURLProtocol.requestHandler = { request in
            if request.httpMethod == "POST",
               let url = request.url,
               url.path.contains("v1/batch") {
                capture.record(request: request)
            }
            return (200, nil, nil)
        }

        defer {
            MockProvider.teardownMockURLSession()
        }

        // 2. Create a real Analytics instance with controlled configuration
        let mockStorage = MockStorage()
        let config = Configuration(
            writeKey: "test-write-key",
            dataPlaneUrl: "https://mock.dataplane.com",
            flushPolicies: [CountFlushPolicy(flushAt: 1)],
            trackApplicationLifecycleEvents: false,
            sessionConfiguration: SessionConfiguration(automaticSessionTracking: false)
        )
        config.storage = mockStorage
        config.storageMode = .memory

        let analytics = Analytics(configuration: config)
        defer { analytics.shutdown() }

        // 3. Track event
        analytics.track(
            name: "Purchase",
            properties: ["amount": 99, "currency": "USD"]
        )

        // 4. Wait for the batch POST request
        let batchRequest = await capture.waitForBatchRequest(timeout: 10.0)
        #expect(batchRequest != nil, "Expected a POST /v1/batch request within timeout")
        guard let batchRequest else { return }

        // 5. Assert request metadata
        #expect(batchRequest.method == "POST")
        #expect(batchRequest.url?.path.contains("v1/batch") == true)

        // Assert Authorization header
        let authHeader = batchRequest.headers?["Authorization"]
        #expect(authHeader != nil, "Expected Authorization header")
        #expect(authHeader?.hasPrefix("Basic ") == true)

        // 6. Parse batch payload
        let bodyData = try #require(batchRequest.body, "Expected request body")
        let json = try #require(
            JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
            "Expected JSON object in request body"
        )

        let batch = try #require(json["batch"] as? [[String: Any]], "Expected 'batch' array in payload")
        #expect(!batch.isEmpty, "Expected at least 1 event in batch")

        // Find the Purchase track event (skip any system events)
        let trackEvent = batch.first {
            ($0["type"] as? String) == "track" && ($0["event"] as? String) == "Purchase"
        }
        #expect(trackEvent != nil, "Expected a track event with name 'Purchase' in batch")
        guard let trackEvent else { return }

        // 7. Assert event fields
        #expect(trackEvent["type"] as? String == "track")
        #expect(trackEvent["event"] as? String == "Purchase")

        // Assert properties
        let properties = trackEvent["properties"] as? [String: Any]
        #expect(properties != nil, "Expected properties in track event")
        #expect(properties?["amount"] as? Int == 99)
        #expect(properties?["currency"] as? String == "USD")

        // Assert required fields
        #expect(trackEvent["messageId"] != nil, "Expected messageId")
        #expect(trackEvent["anonymousId"] != nil, "Expected anonymousId")
        #expect(trackEvent["originalTimestamp"] != nil, "Expected originalTimestamp")
        #expect(trackEvent["context"] != nil, "Expected context")
        #expect(trackEvent["channel"] as? String == "mobile")

        // Assert sentAt at batch level
        #expect(json["sentAt"] != nil, "Expected sentAt in batch payload")
    }
}
