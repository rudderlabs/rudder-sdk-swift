//
//  ScreenInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import UIKit

// MARK: - ScreenInfoPlugin
/**
 A plugin created to append screen information to the message context.
 */
final class ScreenInfoPlugin: ContextInfoPlugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        return self.append(info: ["screen" : self.preparedScreenInfo], to: event)
    }
    
    private var preparedScreenInfo: [String: Any] {
        return ["density": UIScreen.main.scale, "width": UIScreen.main.bounds.size.width, "height": UIScreen.main.bounds.size.height]
    }
}
