//
//  RSClientTests.swift
//  RudderStackTests
//
//  Created by Pallab Maiti on 07/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import XCTest
@testable import RudderStack

let WRITE_KEY = "1wvsoF3Kx2SczQNlx1dvcqW9ODW"
let DATA_PLANE_URL = "https://rudderstacz.dataplane.rudderstack.com"

class RSClientTests: XCTestCase {

    func testBaseEventCreation() {
        let client = RSClient(config: RSConfig(writeKey: WRITE_KEY))
        client.track("Track 1")
    }
    
    // make sure you have Firebase added & enabled to the source in your RudderStack A/C
    func testDestinationEnabled() {
        let expectation = XCTestExpectation(description: "Firebase Expectation")
        let myDestination = FirebaseDestination {
            expectation.fulfill()
            return true
        }
        
        let client = RSClient(config: RSConfig(writeKey: WRITE_KEY).dataPlaneURL(DATA_PLANE_URL))
        client.add(destination: myDestination)
        waitUntilServerConfigDownloaded(client: client)
        waitUntilStarted(client: client)
        client.track("testDestinationEnabled")
        
        wait(for: [expectation], timeout: 2.0)
    }
        
    func testDestinationNotEnabled() {
        let expectation = XCTestExpectation(description: "MyDestination Expectation")
        let myDestination = MyDestination {
            expectation.fulfill()
            return true
        }

        let client = RSClient(config: RSConfig(writeKey: WRITE_KEY).dataPlaneURL(DATA_PLANE_URL))
        client.add(destination: myDestination)
        waitUntilServerConfigDownloaded(client: client)
        waitUntilStarted(client: client)
        client.track("testDestinationEnabled")

        XCTExpectFailure {
            wait(for: [expectation], timeout: 2.0)
        }
    }
}

func waitUntilStarted(client: RSClient?) {
    guard let client = client else { return }
    if let replayQueue = client.find(pluginType: RSReplayQueuePlugin.self) {
        while replayQueue.running == true {
            RunLoop.main.run(until: Date.distantPast)
        }
    }
}

func waitUntilServerConfigDownloaded(client: RSClient?) {
    guard let client = client else { return }
    while client.serverConfig == nil {
        RunLoop.main.run(until: Date.distantPast)
    }
}

class FirebaseDestinationPlugin: RSDestinationPlugin {
    var controller: RSController = RSController()
    var client: RSClient?
    var type: PluginType = .destination
    var key: String = "Firebase"
    
    let trackCompletion: (() -> Bool)?
    
    init(trackCompletion: (() -> Bool)? = nil) {
        self.trackCompletion = trackCompletion
    }
    
    func track(message: TrackMessage) -> TrackMessage? {
        var returnEvent: TrackMessage? = message
        if let completion = trackCompletion {
            if !completion() {
                returnEvent = nil
            }
        }
        return returnEvent
    }
}

class MyDestinationPlugin: RSDestinationPlugin {
    var controller: RSController = RSController()
    var client: RSClient?
    var type: PluginType = .destination
    var key: String = "MyDestination"
    
    let trackCompletion: (() -> Bool)?
    
    init(trackCompletion: (() -> Bool)? = nil) {
        self.trackCompletion = trackCompletion
    }
    
    func track(message: TrackMessage) -> TrackMessage? {
        var returnEvent: TrackMessage? = message
        if let completion = trackCompletion {
            if !completion() {
                returnEvent = nil
            }
        }
        return returnEvent
    }
}

class FirebaseDestination: RudderDestination {
    init(trackCompletion: (() -> Bool)?) {
        super.init()
        plugin = FirebaseDestinationPlugin(trackCompletion: trackCompletion)
    }
}

class MyDestination: RudderDestination {
    init(trackCompletion: (() -> Bool)?) {
        super.init()
        plugin = MyDestinationPlugin(trackCompletion: trackCompletion)
    }
}
