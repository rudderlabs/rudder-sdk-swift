//
//  SessionManagerTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Foundation
import XCTest
@testable import Analytics

final class SessionManagerTests: XCTestCase {
    private var manager: SessionManager?
    private var storage: MockKeyValueStorage?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = MockKeyValueStorage()
        if let storage {
            manager = SessionManager(storage: storage)
        }
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        storage = nil
        manager = nil
    }
    
    func test_startSession_shouldUpdateType_true() {
        given("Prepare sample session information") {
            let sessionId: UInt64 = 123454321
            let sessionType: SessionType = .manual
            
            when("Start a session with sample values") {
                manager?.startSession(id: sessionId, type: sessionType)
                
                then("A new session started...") {
                    XCTAssertTrue(manager?.sessionId == sessionId, "Session ID should be updated correctly")
                    XCTAssertTrue(manager?.isSessionStart == true, "Session should be marked as started")
                    XCTAssertTrue(manager?.sessionType == .manual, "Session type should be manual")
                }
            }
        }
    }
    
    func test_startSession_shouldUpdateType_false() {
        given("Prepare sample session information") {
            let sessionId: UInt64 = 123454321
            let sessionType: SessionType = .manual
            
            when("Start a session with sample values") {
                manager?.startSession(id: sessionId, type: sessionType, shouldUpdateType: false)
                
                then("A new session started...") {
                    XCTAssertTrue(manager?.sessionId == sessionId, "Session ID should be updated correctly")
                    XCTAssertTrue(manager?.isSessionStart == true, "Session should be marked as started")
                    XCTAssertTrue(manager?.sessionType == .automatic, "Session type should be automaic not manual")
                }
            }
        }
    }
    
    func testEndSession_ResetsSession() {
        given("Start a session with a session id..") {
            let sessionId: UInt64 = 123454321
            manager?.startSession(id: sessionId)
            
            when("End the active session...") {
                manager?.endSession()
                
                then("Session will be reset...") {
                    XCTAssertNil(manager?.sessionId, "Session ID should be nil after ending session")
                    XCTAssert(manager?.isSessionStart == false, "Session should be marked as not started")
                }
            }
        }
    }
    
    func testRefreshSession_GeneratesNewSessionId() {
        given("Start a session with a session id..") {
            let sessionId: UInt64 = 123454321
            manager?.startSession(id: sessionId)
            
            when("Refersh the active session...") {
                manager?.refreshSession()
                
                then("Session id will be refreshed...") {
                    XCTAssert(manager?.sessionId != sessionId, "A new session ID should be generated")
                }
            }
        }
    }
}
