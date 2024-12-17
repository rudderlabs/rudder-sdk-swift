//
//  LibraryInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/12/24.
//

import Foundation

// MARK: - LibraryInfoPlugin
/**
 A plugin created to append library information to the message context.
 */
final class LibraryInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        return event.append(info: ["library": self.preparedLibraryInfo])
    }
    
    private var preparedLibraryInfo: [String: Any] = {
        return ["name": "rudder-ios-library", "version": "\(RSVersion)"]
    }()
}
