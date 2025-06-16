//
//  UIKitAutomaticScreenTrackingPlugin.swift
//  AnalyticsAppSwift
//
//  Created by Satheesh Kannan on 30/04/25.
//

import UIKit
import Analytics

// MARK: - UIKitAutomaticScreenTrackingPlugin
/**
 Automatically tracks UIKit screen appearances by swizzling `viewDidAppear` and posting analytics events.
 */
final class UIKitAutomaticScreenTrackingPlugin: Plugin {
    var pluginType: PluginType = .utility
    var analytics: AnalyticsClient?
    
    private var isSwizzled = false
    private var notificationObserver: NSObjectProtocol?
    
    init() {
        self.startTracking()
    }
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    deinit {
        self.stopTracking()
    }
    
    func startTracking() {
        self.performSwizzle(isSwizzling: true)
    }
    
    func stopTracking() {
        self.performSwizzle(isSwizzling: false)
    }
    
    private func performSwizzle(isSwizzling: Bool) {
        isSwizzling ? self.swizzleViewDidAppear() : self.unswizzleViewDidAppear()
    }
    
    fileprivate func logUIKitScreen(viewController: UIViewController) {
        let name = NSStringFromClass(type(of: viewController)).replacingOccurrences(of: "ViewController", with: "")
        let className = name.components(separatedBy: ".").last ?? viewController.title ?? "Unknown"
        
        if let trackableViewController = viewController as? UIKitScreenTrackable {
            trackableViewController.trackUIKitScreen(name: className)
        } else {
            self.analytics?.screen(name: className)
        }
    }
    
    func swizzleViewDidAppear() {
        guard !isSwizzled else { return }
        defer { isSwizzled = true }
        
        guard let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))),
              let swizzled = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.swizzled_viewDidAppear(_:))) else {
            return
        }
        
        method_exchangeImplementations(original, swizzled)
        
        NotificationCenter.default.addObserver(forName: .UIKitScreenTrackingNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self, let viewController = notification.object as? UIViewController, let top = viewController.topViewController, viewController === top
            else { return }
            
            self.logUIKitScreen(viewController: viewController)
        })
    }
    
    func unswizzleViewDidAppear() {
        NotificationCenter.default.removeObserver(self)
        guard isSwizzled else { return }
        defer { isSwizzled = false }

        guard let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))),
              let swizzled = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.swizzled_viewDidAppear(_:))) else {
            return
        }

        method_exchangeImplementations(original, swizzled)
    }
}

// MARK: - UIViewController Swizzling Extension

extension UIViewController {
    @objc fileprivate func swizzled_viewDidAppear(_ animated: Bool) {
        swizzled_viewDidAppear(animated)
        
        guard let top = self.topViewController, self === top else { return }
        NotificationCenter.default.post(name: .UIKitScreenTrackingNotification, object: self)
    }
    
    fileprivate var topViewController: UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController
        
        return Self.visibleViewController(from: root)
    }
    
    private static func visibleViewController(from controller: UIViewController?) -> UIViewController? {
        if let nav = controller as? UINavigationController {
            return visibleViewController(from: nav.visibleViewController)
        }
        if let tab = controller as? UITabBarController {
            return visibleViewController(from: tab.selectedViewController)
        }
        if let presented = controller?.presentedViewController {
            return visibleViewController(from: presented)
        }
        return controller
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let UIKitScreenTrackingNotification = Notification.Name("TrackUIKitScreenNotification")
}

// MARK: - UIKitScreenTrackable

protocol UIKitScreenTrackable {
    func trackUIKitScreen(name: String)
}
