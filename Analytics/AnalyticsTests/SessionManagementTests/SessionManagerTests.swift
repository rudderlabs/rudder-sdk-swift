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
        given("A sample session information") {
            let sessionId: UInt64 = 123454321
            let sessionType: SessionType = .manual
            
            when("Starting a new session with a specific ID and type") {
                manager?.startSession(id: sessionId, type: sessionType)
                
                then("The session should start with the provided values") {
                    XCTAssertEqual(manager?.sessionId, sessionId, "Session ID should be updated correctly")
                    XCTAssertEqual(manager?.isSessionStart, true, "Session should be marked as started")
                    XCTAssertEqual(manager?.sessionType, .manual, "Session type should be manual")
                }
            }
        }
    }
    
    func test_startSession_shouldUpdateType_false() {
        given("An initial session state values") {
            let sessionId: UInt64 = 123454321
            let sessionType: SessionType = .manual
            
            when("Starting a session without updating the session type") {
                manager?.startSession(id: sessionId, type: sessionType, shouldUpdateType: false)
                
                then("The session should start, but the session type should remain unchanged") {
                    XCTAssertTrue(manager?.sessionId == sessionId, "Session ID should be updated correctly")
                    XCTAssertTrue(manager?.isSessionStart == true, "Session should be marked as started")
                    XCTAssertTrue(manager?.sessionType == .automatic, "Session type should remain automatic, not manual")
                }
            }
        }
    }
    
    func testEndSession_ResetsSession() {
        given("A session manager with an active session") {
            let sessionId: UInt64 = 123454321
            manager?.startSession(id: sessionId)
            
            when("Ending the active session") {
                manager?.endSession()
                
                then("The session should reset to its initial state") {
                    XCTAssertNil(manager?.sessionId, "Session ID should be nil after ending session")
                }
            }
        }
    }
    
    func testRefreshSession_GeneratesNewSessionId() {
        given("A session manager with an active session") {
            let sessionId: UInt64 = 123454321
            manager?.startSession(id: sessionId)
            
            when("Refreshing the active session") {
                manager?.refreshSession()
                
                then("A new session ID should be generated") {
                    XCTAssert(manager?.sessionId != sessionId, "A new session ID should be generated")
                    XCTAssert(manager?.isSessionStart == true, "Session should be marked as started")
                }
            }
        }
    }
}
