//
//  EventUploaderTests.swift
//  RudderStackAnalyticsTests
//

import XCTest
@testable import RudderStackAnalytics

final class EventUploaderTests: XCTestCase {
    
    private var mockAnalytics: Analytics!
    private var eventUploader: EventUploader!
    private var uploadChannel: AsyncChannel<String>!
    
    override func setUp() {
        super.setUp()
        mockAnalytics = MockProvider.clientWithDiskStorage
        uploadChannel = AsyncChannel<String>()
        eventUploader = EventUploader(analytics: mockAnalytics, uploadChannel: uploadChannel)
    }
    
    override func tearDown() {
        super.tearDown()
        eventUploader?.stop()
        eventUploader = nil
        uploadChannel = nil
        mockAnalytics = nil
    }
    
    func test_extractAnonymousIdFromBatch_withValidAnonymousId_returnsCorrectId() {
        let batchPayload = """
        {"userId": "12345", "anonymousId": "abc-123", "event": "test"}
        """
        let expectedAnonymousId = "abc-123"
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertEqual(extractedId, expectedAnonymousId)
    }
    
    func test_extractAnonymousIdFromBatch_withDifferentFormatting_returnsCorrectId() {
        let batchPayload = """
        {"userId": "12345", "event": "test", "anonymousId":"xyz-456"}
        """
        let expectedAnonymousId = "xyz-456"
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertEqual(extractedId, expectedAnonymousId)
    }
    
    func test_extractAnonymousIdFromBatch_withSpacesInValue_returnsCorrectId() {
        let batchPayload = """
        {"anonymousId": "lmn-789"}
        """
        let expectedAnonymousId = "lmn-789"
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertEqual(extractedId, expectedAnonymousId)
    }
    
    func test_extractAnonymousIdFromBatch_withFirstOccurrence_returnsFirstMatch() {
        let batchPayload = """
        {"anonymousId": "first-id", "data": {"anonymousId": "second-id"}}
        """
        let expectedAnonymousId = "first-id"
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertEqual(extractedId, expectedAnonymousId)
    }
    
    func test_extractAnonymousIdFromBatch_withNoAnonymousId_returnsNil() {
        let batchPayload = """
        {"userId": "12345", "event": "test"}
        """
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertNil(extractedId)
    }
    
    func test_extractAnonymousIdFromBatch_withEmptyString_returnsNil() {
        let batchPayload = ""
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertNil(extractedId)
    }
    
    func test_extractAnonymousIdFromBatch_withMalformedJson_returnsNil() {
        let batchPayload = """
        {"userId": "12345", "event": "test"
        """
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertNil(extractedId)
    }
    
    func test_extractAnonymousIdFromBatch_withComplexBatchPayload_returnsCorrectId() {
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
        
        XCTAssertEqual(extractedId, expectedAnonymousId)
    }
    
    func test_extractAnonymousIdFromBatch_withSpecialCharacters_returnsCorrectId() {
        let batchPayload = """
        {"anonymousId": "id-with-special-chars_123-456@domain.com"}
        """
        let expectedAnonymousId = "id-with-special-chars_123-456@domain.com"
        
        let extractedId = eventUploader.extractAnonymousIdFromBatch(batchPayload)
        
        XCTAssertEqual(extractedId, expectedAnonymousId)
    }
}
