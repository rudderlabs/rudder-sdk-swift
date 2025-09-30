//
//  EventUploaderTests.swift
//  RudderStackAnalyticsTests
//

import Testing
@testable import RudderStackAnalytics

struct EventUploaderTests {

    private let mockAnalytics: Analytics
    private let eventUploader: EventUploader
    private let uploadChannel: AsyncChannel<String>

    init() {
        mockAnalytics = MockProvider.clientWithDiskStorage
        uploadChannel = AsyncChannel<String>()
        eventUploader = EventUploader(analytics: mockAnalytics, uploadChannel: uploadChannel)
    }
    
    @Test("Extract anonymousId from batch with valid anonymousId returns correct id")
    func extractAnonymousIdFromBatch_withValidAnonymousId_returnsCorrectId() {
        let batchPayload = """
        {"userId": "12345", "anonymousId": "abc-123", "event": "test"}
        """
        let expectedAnonymousId = "abc-123"

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == expectedAnonymousId)
    }
    
    @Test("Extract anonymousId from batch with different formatting returns correct id")
    func extractAnonymousIdFromBatch_withDifferentFormatting_returnsCorrectId() {
        let batchPayload = """
        {"userId": "12345", "event": "test", "anonymousId":"xyz-456"}
        """
        let expectedAnonymousId = "xyz-456"

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == expectedAnonymousId)
    }
    
    @Test("Extract anonymousId from batch with spaces in value returns correct id")
    func extractAnonymousIdFromBatch_withSpacesInValue_returnsCorrectId() {
        let batchPayload = """
        {"anonymousId": "lmn-789"}
        """
        let expectedAnonymousId = "lmn-789"

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == expectedAnonymousId)
    }
    
    @Test("Extract anonymousId from batch with first occurrence returns first match")
    func extractAnonymousIdFromBatch_withFirstOccurrence_returnsFirstMatch() {
        let batchPayload = """
        {"anonymousId": "first-id", "data": {"anonymousId": "second-id"}}
        """
        let expectedAnonymousId = "first-id"

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == expectedAnonymousId)
    }
    
    @Test("Extract anonymousId from batch with no anonymousId returns nil")
    func extractAnonymousIdFromBatch_withNoAnonymousId_returnsNil() {
        let batchPayload = """
        {"userId": "12345", "event": "test"}
        """

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == nil)
    }
    
    @Test("Extract anonymousId from batch with empty string returns nil")
    func extractAnonymousIdFromBatch_withEmptyString_returnsNil() {
        let batchPayload = ""

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == nil)
    }
    
    @Test("Extract anonymousId from batch with malformed JSON returns nil")
    func extractAnonymousIdFromBatch_withMalformedJson_returnsNil() {
        let batchPayload = """
        {"userId": "12345", "event": "test"
        """

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == nil)
    }
    
    @Test("Extract anonymousId from batch with complex batch payload returns correct id")
    func extractAnonymousIdFromBatch_withComplexBatchPayload_returnsCorrectId() {
        let batchPayload = """
        {
          "batch": [
            {
              "userId": "user123",
              "anonymousId": "batch-anon-id",
              "event": "Track",
              "properties": {
                "category": "test"
              },
              "context": {
                "app": {
                  "name": "TestApp"
                }
              }
            }
          ]
        }
        """
        let expectedAnonymousId = "batch-anon-id"

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == expectedAnonymousId)
    }
    
    @Test("Extract anonymousId from batch with special characters returns correct id")
    func extractAnonymousIdFromBatch_withSpecialCharacters_returnsCorrectId() {
        let batchPayload = """
        {"anonymousId": "id-with-special-chars_123-456@domain.com"}
        """
        let expectedAnonymousId = "id-with-special-chars_123-456@domain.com"

        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)

        #expect(extractedId == expectedAnonymousId)
    }
}
