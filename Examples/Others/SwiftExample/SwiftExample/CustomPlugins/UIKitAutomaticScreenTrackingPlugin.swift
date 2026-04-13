//
//  UIKitAutomaticScreenTrackingPlugin.swift
//  SwiftExample
//
//  Created by Satheesh Kannan on 30/04/25.
//

import UIKit
import RudderStackAnalytics

// MARK: - UIKitAutomaticScreenTrackingPlugin
/**
 This plugin automatically tracks when users navigate to different screens in your iOS app. It works by monitoring when view controllers appear on screen.
 
 ## How it works:
 The plugin uses a technique called "method swizzling" to intercept the `viewDidAppear` method that gets called every time a screen appears. When this happens, it automatically sends a screen tracking event with the screen name.
 
 ## Screen names:
    - Uses the view controller's class name (e.g., "LoginViewController" becomes "Login")
    - Falls back to the view controller's title if available
    - Uses "Unknown" if neither is available
 
 ## Usage:
 
 ```swift
 // Add the plugin to your analytics instance
 let screenTrackingPlugin = UIKitAutomaticScreenTrackingPlugin()
 analytics.add(plugin: screenTrackingPlugin)
  
 // That's it! Screen tracking will now happen automatically
 ```
 
 ## Custom screen tracking:
 If you want to customize how a specific screen is tracked, make your view controller
 conform to `UIKitScreenTrackable` protocol:
 
 ```swift
 class MyViewController: UIViewController, UIKitScreenTrackable {
    func trackUIKitScreen(name: String) {
        // Custom tracking logic here
        analytics.screen(screenName: "My Custom Screen Name")
    }
 }
 ```
 - Important: This plugin only works with UIKit-based view controllers
 */

final class UIKitAutomaticScreenTrackingPlugin: Plugin {
    var pluginType: PluginType = .utility
    var analytics: Analytics?
    
    /** Keeps track of whether we've already set up the automatic tracking */
    private var isSwizzled = false
    
    /** Stores the notification observer so we can clean it up later */
    private var notificationObserver: NSObjectProtocol?
    
    /** Creates a new screen tracking plugin and starts tracking automatically */
    init() {
        self.startTracking()
    }
    
    /**
     Called by RudderStack when the plugin is added to the analytics instance
     
     - Parameter analytics: The analytics instance this plugin is attached to
     */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /** Cleans up when the plugin is destroyed */
    deinit {
        self.stopTracking()
    }
    
    /** Starts automatic screen tracking */
    func startTracking() {
        self.performSwizzle(isSwizzling: true)
    }
    
    /** Stops automatic screen tracking and cleans up */
    func stopTracking() {
        self.performSwizzle(isSwizzling: false)
    }
    
    /**
     Helper method that either starts or stops the method swizzling
     
     - Parameter isSwizzling: true to start tracking, false to stop
     */
    private func performSwizzle(isSwizzling: Bool) {
        isSwizzling ? self.swizzleViewDidAppear() : self.unswizzleViewDidAppear()
    }
    
    /**
     Sends a screen tracking event to analytics
     
     - Parameter viewController: The view controller that appeared on screen
     */
    fileprivate func logUIKitScreen(viewController: UIViewController) {
        // Create a clean screen name by removing "ViewController" from the class name
        let name = NSStringFromClass(type(of: viewController)).replacingOccurrences(of: "ViewController", with: "")
        // Get just the class name without the module prefix (e.g., "MyApp.LoginViewController" -> "Login")
        let className = name.components(separatedBy: ".").last ?? viewController.title ?? "Unknown"
        
        // Check if the view controller wants to handle its own screen tracking
        if let trackableViewController = viewController as? UIKitScreenTrackable {
            trackableViewController.trackUIKitScreen(name: className)
        } else {
            // Send the standard screen tracking event
            self.analytics?.screen(screenName: className)
        }
    }
    
    /** Sets up method swizzling to intercept viewDidAppear calls */
    func swizzleViewDidAppear() {
        // Don't set up swizzling if it's already done
        guard !isSwizzled else { return }
        defer { isSwizzled = true }
        
        // Get the original and our custom viewDidAppear methods
        guard let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))),
              let swizzled = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.swizzled_viewDidAppear(_:))) else {
            return
        }
        
        // Swap the implementations so our custom method gets called instead
        method_exchangeImplementations(original, swizzled)
        
        // Listen for notifications when screens appear
        NotificationCenter.default.addObserver(forName: .UIKitScreenTrackingNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self, let viewController = notification.object as? UIViewController, let top = viewController.topViewController, viewController === top
            else { return }
            
            // Send the screen tracking event
            self.logUIKitScreen(viewController: viewController)
        })
    }
    
    /** Removes method swizzling and stops tracking */
    func unswizzleViewDidAppear() {
        // Stop listening to notifications
        NotificationCenter.default.removeObserver(self)
        // Don't do anything if swizzling wasn't set up
        guard isSwizzled else { return }
        defer { isSwizzled = false }

        // Get the methods again and swap them back to their original implementations
        guard let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))),
              let swizzled = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.swizzled_viewDidAppear(_:))) else {
            return
        }

        // Swap back to restore the original behavior
        method_exchangeImplementations(original, swizzled)
    }
}

// MARK: - UIViewController Swizzling Extension

extension UIViewController {
    /**
     Our custom viewDidAppear method that gets swapped in place of the original
     
     - Parameter animated: Whether the appearance is animated
     */
    @objc fileprivate func swizzled_viewDidAppear(_ animated: Bool) {
        // Call the original viewDidAppear method (this actually calls the original because of swizzling)
        swizzled_viewDidAppear(animated)
        
        // Only track if this is the top-most visible view controller
        guard let top = self.topViewController, self === top else { return }
        // Send a notification that this screen appeared
        NotificationCenter.default.post(name: .UIKitScreenTrackingNotification, object: self)
    }
    
    /**
     Finds the currently visible view controller on screen.
     This handles navigation controllers, tab controllers, and presented view controllers
     */
    fileprivate var topViewController: UIViewController? {
        // Find the main window of the app
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController
        
        // Walk through the view controller hierarchy to find the visible one
        return Self.visibleViewController(from: root)
    }
    
    /**
     Recursively finds the visible view controller by checking navigation, tab, and presented controllers
     
     - Parameter controller: The root controller to start searching from
     - Returns: The currently visible view controller
     */
    private static func visibleViewController(from controller: UIViewController?) -> UIViewController? {
        // If it's a navigation controller, check what's currently visible
        if let nav = controller as? UINavigationController {
            return visibleViewController(from: nav.visibleViewController)
        }
        // If it's a tab controller, check the selected tab
        if let tab = controller as? UITabBarController {
            return visibleViewController(from: tab.selectedViewController)
        }
        // If something is presented (like a modal), that's what's visible
        if let presented = controller?.presentedViewController {
            return visibleViewController(from: presented)
        }
        // Otherwise, this is the visible controller
        return controller
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    /** Custom notification name used internally for screen tracking */
    static let UIKitScreenTrackingNotification = Notification.Name("TrackUIKitScreenNotification")
}

// MARK: - UIKitScreenTrackable

/**
 UIKitScreenTrackable Protocol
 
 Implement this protocol in your view controllers if you want to customize how screen tracking works for that specific screen.
 
 ## Usage:
 ```swift
 class MyViewController: UIViewController, UIKitScreenTrackable {
    func trackUIKitScreen(name: String) {
        // Your custom screen tracking logic here
        analytics.screen(screenName: "My Custom Screen Name", properties: ["custom": "data"])
    }
 }
 ```
 */
protocol UIKitScreenTrackable {
    /**
     Called when this view controller appears on screen
     
     - Parameter name: The suggested screen name (usually the class name)
     */
    func trackUIKitScreen(name: String)
}
