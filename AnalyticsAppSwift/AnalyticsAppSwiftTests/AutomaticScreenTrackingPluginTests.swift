//
//  AutomaticScreenTrackingPluginTests.swift
//  AnalyticsAppSwiftTests
//
//  Created by Satheesh Kannan on 30/04/25.
//

import Testing
import UIKit
import Analytics
@testable import AnalyticsAppSwift

struct AutomaticScreenTrackingPluginTests {
    @Test
    func test_plugin_swizzle_tracking() {
        given("a screen tracking plugin and a mock view controller") {
            _ = UIKitAutomaticScreenTrackingPlugin()

            DispatchQueue.main.sync {
                let vc = MockViewController()
                
                when("the view controller is set as the root and a tracking notification is posted") {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                        window.rootViewController = vc
                    }

                    NotificationCenter.default.post(name: .UIKitScreenTrackingNotification, object: vc)

                    then("the plugin should log the screen with the view controller's name") {
                        #expect(vc.trackedScreenName == "Mock")
                    }
                }
            }
        }
    }
    
    @Test
    func test_plugin_unswizzle_stops_tracking() {
        given("an initialized screen tracking plugin and a mock view controller") {
            let plugin = UIKitAutomaticScreenTrackingPlugin()
            plugin.startTracking()
            
            DispatchQueue.main.sync {
                let vc = MockViewController()
                
                when("tracking is stopped and viewDidAppear is called") {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                        window.rootViewController = vc
                    }
                    
                    plugin.stopTracking()
                    
                    // Simulate lifecycle
                    vc.beginAppearanceTransition(true, animated: false)
                    vc.endAppearanceTransition()
                    
                    then("the screen name should not be tracked") {
                        print("Tracked screen name: \(vc.trackedScreenName)")
                        #expect(vc.trackedScreenName.isEmpty == true)
                    }
                }
            }
        }
    }
}

class MockViewController: UIViewController, UIKitScreenTrackable {
    
    var trackedScreenName: String = ""
    
    func trackUIKitScreen(name: String) {
        self.trackedScreenName = name
    }
}

/*
import XCTest
import Testing
@testable import YourModuleName

final class UIKitAutomaticScreenTrackingPluginTests: XCTestCase {

    func test_plugin_unswizzle_stops_tracking() {
        given("a plugin that has started tracking") {
            let plugin = UIKitAutomaticScreenTrackingPlugin()
            let mockAnalytics = AnalyticsClientMock()
            plugin.setup(analytics: mockAnalytics)

            class DummyVC: UIViewController {}
            let dummyVC = DummyVC()
            UIApplication.shared.keyWindow?.rootViewController = dummyVC

            when("stopTracking is called") {
                plugin.stopTracking()
                NotificationCenter.default.post(name: .UIKitScreenTrackingNotification, object: dummyVC)

                then("it should not log any screen events") {
                    XCTAssertFalse(mockAnalytics.screenNames.contains(where: { $0.contains("Dummy") }))
                }
            }
        }
    }
}

protocol AnalyticsReporting {
    func screen(name: String)
}

final class AnalyticsClientMock: AnalyticsReporting {
    var screenNames = [String]()
    func screen(name: String) {
        screenNames.append(name)
    }
}

what about this..
*/
