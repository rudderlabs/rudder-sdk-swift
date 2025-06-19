//
//  SessionHandlerTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

import XCTest
@testable import RudderStackAnalytics

final class SessionHandlerTests: XCTestCase {
    private var analytics: AnalyticsClient?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        analytics = nil
    }
    
    func test_startSession() {
        given("A sample session information") {
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            let sessionId: UInt64 = 123454321
            let sessionType: SessionType = .manual
            
            let manager = SessionHandler(analytics: analytics)
            
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
    
    func testEndSession() {
        given("A session manager with an active session") {
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)

            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            let sessionId: UInt64 = 123454321
            
            let manager = SessionHandler(analytics: analytics)
            manager.startSession(id: sessionId, type: .manual)
            
            when("Ending the active session") {
                manager.endSession()
                
                then("The session should reset to its initial state") {
                    XCTAssertNil(manager.sessionId, "Session ID should be nil after ending session")
                }
            }
        }
    }
    
    func testRefreshSession() {
        given("A session manager with an active session") {
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            let sessionId: UInt64 = 123454321
                    
            let manager = SessionHandler(analytics: analytics)
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
    
    func test_automaticSession_StartsNewSessionWhenNeeded() {
        given("An automatic session tracking enabled session configuration") {
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            
            when("Start automatic session while there is no active session") {
                let manager = SessionHandler(analytics: analytics)
                
                then("A new session should be started") {
                    XCTAssertNotNil(manager.sessionId, "A session should be started")
                    XCTAssertEqual(manager.sessionType, .automatic, "Session type should be automatic")
                    XCTAssertEqual(manager.isSessionStart, true, "Session should be marked as started")
                }
            }
        }
    }
    
    func test_automaticSession_EndsSessionWhenTrackingDisabled() {
        given("A session manager with an active automatic session but tracking disabled") {
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            
            let manager = SessionHandler(analytics: analytics)
            manager.startSession(id: 12345, type: .automatic)
            
            when("Validate the automatic session") {
                manager.startAutomaticSessionIfNeeded()
                
                then("The session should be ended") {
                    XCTAssertNil(manager.sessionId, "Session should be ended when automatic tracking is disabled")
                }
            }
        }
    }
    
    func test_appBackgroundAndForeground_SessionTimeoutBehavior() {
        given("A session manager with automatic tracking enabled") {
            let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 2000)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            
            let manager = SessionHandler(analytics: analytics)
            
            manager.startSession(id: 12345, type: .automatic)
            let initialSessionId = manager.sessionId

#if os(iOS) || os(tvOS)
            // iOS, Mac Catalyst (UIKit)
            let backgroundNotification = UIApplication.didEnterBackgroundNotification
            let foregroundNotification = UIApplication.willEnterForegroundNotification
#elseif os(macOS)
            // macOS (AppKit)
            let backgroundNotification = NSApplication.didResignActiveNotification
            let foregroundNotification = NSApplication.willBecomeActiveNotification
#elseif os(watchOS)
            // watchOS
            let backgroundNotification = WKApplication.didEnterBackgroundNotification
            let foregroundNotification = WKApplication.willEnterForegroundNotification
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
    

    func test_mixManualSession_withAutomaticSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
        
        given("A session manager with automatic tracking enabled") {
            let configuration = SessionConfiguration(automaticSessionTracking: true)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            let manager = SessionHandler(analytics: analytics)
            
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
            let configuration = SessionConfiguration(automaticSessionTracking: false)
            self.analytics = MockProvider.clientWithSessionConfig(config: configuration)
            
            guard let analytics = self.analytics else { XCTFail("Analytics not initialized"); return }
            let manager = SessionHandler(analytics: analytics)
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
