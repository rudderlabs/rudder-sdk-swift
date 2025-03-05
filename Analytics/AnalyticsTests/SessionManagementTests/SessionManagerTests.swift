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
    private var storage: MockKeyValueStorage?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = MockKeyValueStorage()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        storage = nil
    }
    
    func test_startSession() {
        given("A sample session information") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            let sessionId: UInt64 = 123454321
            let sessionType: SessionType = .manual
            
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            when("Starting a new session with a specific ID and type") {
                manager.startSession(id: sessionId, type: sessionType)
                
                then("The session should start with the provided values") {
                    XCTAssertEqual(manager.sessionId, sessionId, "Session ID should be updated correctly")
                    XCTAssertEqual(manager.isSessionStart, true, "Session should be marked as started")
                    XCTAssertEqual(manager.sessionType, .manual, "Session type should be manual")
                }
            }
        }
    }
    
    func testEndSession_ResetsSession() {
        given("A session manager with an active session") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            let sessionId: UInt64 = 123454321
            
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            manager.startSession(id: sessionId, type: .manual)
            
            when("Ending the active session") {
                manager.endSession()
                
                then("The session should reset to its initial state") {
                    XCTAssertNil(manager.sessionId, "Session ID should be nil after ending session")
                }
            }
        }
    }
    
    func testRefreshSession_GeneratesNewSessionId() {
        given("A session manager with an active session") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            let sessionId: UInt64 = 123454321
            
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            manager.startSession(id: sessionId, type: .manual)
            
            when("Refreshing the active session") {
                manager.refreshSession()
                
                then("A new session ID should be generated") {
                    XCTAssert(manager.sessionId != sessionId, "A new session ID should be generated")
                    XCTAssert(manager.isSessionStart == true, "Session should be marked as started")
                }
            }
        }
    }
    
    func test_ensureAutomaticSession_StartsNewSessionWhenNeeded() {
        given("A session manager with automatic session tracking enabled") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            when("Ensuring automatic session while there is no active session") {
                manager.ensureAutomaticSession()
                
                then("A new session should be started") {
                    XCTAssertNotNil(manager.sessionId, "A session should be started")
                    XCTAssertEqual(manager.sessionType, .automatic, "Session type should be automatic")
                    XCTAssertEqual(manager.isSessionStart, true, "Session should be marked as started")
                }
            }
        }
    }
    
    func test_ensureAutomaticSession_EndsSessionWhenTrackingDisabled() {
        given("A session manager with an active automatic session but tracking disabled") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
        
            manager.startSession(id: 12345, type: .automatic)            
            
            when("Ensuring automatic session") {
                manager.ensureAutomaticSession()
                
                then("The session should be ended") {
                    XCTAssertNil(manager.sessionId, "Session should be ended when automatic tracking is disabled")
                }
            }
        }
    }
    
    func test_appBackgroundAndForeground_SessionTimeoutBehavior() {
        given("A session manager with automatic tracking enabled") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 2000)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            manager.startSession(id: 12345, type: .automatic)
            let initialSessionId = manager.sessionId
            
#if os(macOS)
            // macOS (AppKit)
            let backgroundNotification = NSApplication.didResignActiveNotification
            let foregroundNotification = NSApplication.didBecomeActiveNotification
#else
            // iOS, tvOS, watchOS, and Mac Catalyst (UIKit)
            let backgroundNotification = UIApplication.didEnterBackgroundNotification
            let foregroundNotification = UIApplication.willEnterForegroundNotification
#endif
            
            when("The app moves to the background") {
                NotificationCenter.default.post(name: backgroundNotification, object: nil)
                
                then("The session's last activity time should update") {
                    XCTAssertFalse(manager.isSessionTimedOut, "Session should not immediately be timed out after backgrounding")
                }
            }
            
            when("The app comes back to the foreground before timeout") {
                let timeInterval = manager.monotonicCurrentTime - 1000
                manager.updateSessionLastActivityTime(timeInterval)
                
                NotificationCenter.default.post(name: foregroundNotification, object: nil)
                
                then("A new session should not be started") {
                    XCTAssertFalse(manager.isSessionTimedOut, "Session should be timed out")
                    XCTAssertEqual(manager.sessionId, initialSessionId, "A new session should be created after timeout")
                }
            }
            
            when("The app comes back to the foreground after timeout") {
                NotificationCenter.default.post(name: backgroundNotification, object: nil)
                
                let timeInterval = manager.monotonicCurrentTime - 3000
                manager.updateSessionLastActivityTime(timeInterval)
                
                NotificationCenter.default.post(name: foregroundNotification, object: nil)
                
                then("A new session should be started if timed out") {
                    XCTAssertTrue(manager.isSessionTimedOut, "Session should be timed out")
                    XCTAssertNotEqual(manager.sessionId, initialSessionId, "A new session should be created after timeout")
                }
            }
        }
    }
    
    // TODO: This test case will be moved to observer pattern in future..
    func testAttachObservers_RegistersNotifications() {
        given("A session manager instance") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            when("Attaching observers") {
                manager.attachObservers()
                
                then("Observers should be registered") {
                    XCTAssertNotNil(manager.backgroundObserver, "Background observer should be registered")
                    XCTAssertNotNil(manager.foregroundObserver, "Foreground observer should be registered")
                    XCTAssertNotNil(manager.terminateObserver, "Terminate observer should be registered")
                }
            }
        }
    }
    
    // TODO: This section will be moved to observer pattern in future..
    func testDetachObservers_RemovesNotifications() {
        given("A session manager with active observers") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            manager.attachObservers()
            
            when("Detaching observers") {
                manager.detachObservers()
                
                then("Observers should be removed") {
                    XCTAssertNil(manager.backgroundObserver, "Background observer should be removed")
                    XCTAssertNil(manager.foregroundObserver, "Foreground observer should be removed")
                    XCTAssertNil(manager.terminateObserver, "Terminate observer should be removed")
                }
            }
        }
    }
    
    func test_mixManualSession_withAutomaticSession() {
        given("A session manager with automatic tracking enabled") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            when("Start a manual session") {
                manager.startSession(id: 1234567, type: .manual)
                
                then("A new manual session should be started") {
                    XCTAssertNotNil(manager.sessionId, "A session should be started")
                    XCTAssertEqual(manager.sessionType, .manual, "Session type should be automatic")
                    XCTAssertEqual(manager.isSessionStart, true, "Session should be marked as started")
                }
            }
        }
    }
    
    func test_mixAutomaticSession_withManualSession() {
        given("A session manager with automatic tracking disabled") {
            guard let storage else { XCTFail("Storage not initialized"); return }
            
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            let manager = SessionManager(storage: storage, sessionConfiguration: configuration)
            
            manager.startSession(id: 1234567, type: .manual)
            
            when("Start an automatic session") {
                manager.startSession(id: 123456789, type: .automatic)
                
                then("A new automatic session should be started") {
                    XCTAssertNotEqual(manager.sessionId, 1234567,"A session should be started")
                    XCTAssertEqual(manager.sessionType, .automatic, "Session type should be automatic")
                    XCTAssertEqual(manager.isSessionStart, true, "Session should be marked as started")
                }
            }
        }
    }
}
