//
//  AutomaticScreenTrackingPluginTests.swift
//  SwiftExampleTests
//
//  Created by Satheesh Kannan on 30/04/25.
//

import Testing
import UIKit
import RudderStackAnalytics
@testable import SwiftExample

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
