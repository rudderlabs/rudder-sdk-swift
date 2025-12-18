//
//  SetATTTrackingStatusPluginTests.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 18/12/25.
//

import Testing
import RudderStackAnalytics
@testable import SwiftUIExampleApp

struct SetATTTrackingStatusPluginTests {

    @Test("given SetATTTrackingStatusPlugin with various ATT status values, when plugin intercepts events, then correct status values are set", arguments: [
        0 as UInt, // notDetermined
        1 as UInt, // restricted
        2 as UInt, // denied
        3 as UInt  // authorized
    ])
    func testATTTrackingStatus_handlesAllValidStatusValues(_ statusValue: UInt) {
        let plugin = SetATTTrackingStatusPlugin(attTrackingStatus: statusValue)
        let event = MockEvent()
        event.context = [
            "device": [
                "model": "iPhone",
                "token": "abc123"
            ]
        ].codableWrapped
        
        let result = plugin.intercept(event: event)

        guard let contextDict = result?.context?.rawDictionary,
              let deviceContext = contextDict["device"] as? [String: Any] else {
            #expect(Bool(false), "Device context should be created for ATT status \(statusValue)")
            return
        }
        
        #expect(deviceContext["attTrackingStatus"] as? Int == Int(statusValue))
        #expect(deviceContext["model"] as? String == "iPhone")
        #expect(deviceContext["token"] as? String == "abc123")
    }
    
    @Test("given SetATTTrackingStatusPlugin with status 1 and event with existing attTrackingStatus, when plugin intercepts event, then existing attTrackingStatus is replaced and other fields preserved")
    func testATTTrackingStatus_replacesExistingStatus_inDeviceContext() {
        let plugin = SetATTTrackingStatusPlugin(attTrackingStatus: 1)
        let event = MockEvent()
        event.context = [
            "device": [
                "attTrackingStatus": 3,
                "model": "iPad",
                "identifier": "device123"
            ]
        ].codableWrapped

        let result = plugin.intercept(event: event)

        guard let contextDict = result?.context?.rawDictionary,
              let deviceContext = contextDict["device"] as? [String: Any] else {
            #expect(Bool(false), "Device context should be preserved when replacing ATT status")
            return
        }
        #expect(deviceContext["attTrackingStatus"] as? Int == 1)
        #expect(deviceContext["model"] as? String == "iPad")
        #expect(deviceContext["identifier"] as? String == "device123")
    }

    @Test("given SetATTTrackingStatusPlugin and event with existing context but no device section, when plugin intercepts event, then device section is created with attTrackingStatus and existing context preserved")
    func testATTTrackingStatus_createsDeviceSection_whenContextExistsButNoDevice() {
        let plugin = SetATTTrackingStatusPlugin(attTrackingStatus: 3)
        let event = MockEvent()
        event.context = [
            "app": [
                "name": "TestApp",
                "version": "1.0.0"
            ],
            "library": [
                "name": "RudderStack",
                "version": "2.0.0"
            ]
        ].codableWrapped

        let result = plugin.intercept(event: event)

        guard let contextDict = result?.context?.rawDictionary else {
            #expect(Bool(false), "Context should be preserved when adding device section")
            return
        }
        
        // Check device section was created with attTrackingStatus
        guard let deviceContext = contextDict["device"] as? [String: Any] else {
            #expect(Bool(false), "Device section should be created when missing")
            return
        }
        #expect(deviceContext["attTrackingStatus"] as? Int == 3)
        
        // Check existing context sections are preserved
        #expect(contextDict["app"] != nil)
        #expect(contextDict["library"] != nil)
    }

    @Test("given SetATTTrackingStatusPlugin, when checking plugin type, then returns preProcess")
    func testPluginType() {
        let plugin = SetATTTrackingStatusPlugin(attTrackingStatus: 1)
        
        #expect(plugin.pluginType == .preProcess)
    }
}
