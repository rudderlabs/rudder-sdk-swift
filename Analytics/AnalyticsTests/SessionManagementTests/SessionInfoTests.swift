//
//  SessionInfoTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 26/02/25.
//

import Foundation
import XCTest
@testable import Analytics

final class SessionInfoTests: XCTestCase {
    
    private var storage: MockKeyValueStorage?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = MockKeyValueStorage()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        storage = nil
    }
    
    func test_initializeState_emptyStorage() {
        given("Prepare empty storage..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            when("SessionInfo initialized using empty storage.") {
                let sessionInfo = SessionInfo.initializeState(storage)
                
                then("SessionInfo initialized with default values") {
                    XCTAssertTrue(sessionInfo.id == SessionConstants.defaultSessionId)
                    XCTAssertTrue(sessionInfo.isStart == SessionConstants.defaultIsSessionStart)
                    XCTAssertTrue(sessionInfo.type == SessionConstants.defaultSessionType)
                }
            }
        }
    }
    
    func test_initializeState_notEmptyStorage() {
        given("Prepare storage with values..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let expectedSessionId = "12312123"
            let expectedIsSessionStart = true
            let expectedSessionType = SessionType.manual
            
            storage.write(value: expectedSessionId, key: Constants.StorageKeys.sessionId)
            storage.write(value: expectedIsSessionStart, key: Constants.StorageKeys.isSessionStart)
            storage.write(value: expectedSessionType == .manual, key: Constants.StorageKeys.isManualSession)
            
            when("SessionInfo initialized.") {
                let sessionInfo = SessionInfo.initializeState(storage)
                
                then("UserIdentity initialized with storage values") {
                    XCTAssertTrue(String(sessionInfo.id) == expectedSessionId)
                    XCTAssertTrue(sessionInfo.isStart == expectedIsSessionStart)
                    XCTAssertTrue(sessionInfo.type == expectedSessionType)
                }
            }
        }
    }
}
