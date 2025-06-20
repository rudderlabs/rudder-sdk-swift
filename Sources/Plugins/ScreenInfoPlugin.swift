//
//  ScreenInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - ScreenInfoPlugin
/**
 A plugin created to append screen information to the event context.
 */
final class ScreenInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: ["screen": self.preparedScreenInfo])
    }
    
    private var preparedScreenInfo: [String: Any] = {
#if os(iOS) || os(tvOS)
        let scale = UIScreen.main.scale
        let size = UIScreen.main.bounds.size

#elseif os(macOS)
        guard let screen = NSScreen.main else { return [:] }
        let scale = screen.backingScaleFactor
        let size = screen.frame.size
        
#elseif os(watchOS)
        let scale = WKInterfaceDevice.current().screenScale
        let size = WKInterfaceDevice.current().screenBounds.size
#endif
        return ["density": scale, "width": size.width, "height": size.height]
    }()
}
