//
//  AppInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/12/24.
//

import Foundation

// MARK: - AppInfoPlugin
/**
 A plugin created to append app information to the event context.
 */
final class AppInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let info = self.preparedAppInfo else { return event }
        return event.addToContext(info: ["app": info])
    }
    
    private var preparedAppInfo: [String: Any]? = {
        guard let bundle = Bundle.main.infoDictionary else { return nil }
        return [
            "build": bundle["CFBundleVersion"] as? String,
            "name": bundle["CFBundleName"] as? String,
            "namespace": Bundle.main.bundleIdentifier,
            "version": bundle["CFBundleShortVersionString"] as? String
        ].compactMapValues { $0 }
    }()
}
