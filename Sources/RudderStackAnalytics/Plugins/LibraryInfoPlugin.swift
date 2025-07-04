//
//  LibraryInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/12/24.
//

import Foundation

// MARK: - LibraryInfoPlugin
/**
 A plugin created to append library information to the event context.
 */
final class LibraryInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: ["library": self.preparedLibraryInfo])
    }
    
    private var preparedLibraryInfo: [String: Any] = {
        return ["name": RSLibraryName, "version": RSVersion]
    }()
}
