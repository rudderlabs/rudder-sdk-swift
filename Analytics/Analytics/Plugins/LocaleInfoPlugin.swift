//
//  LocaleInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import Foundation

// MARK: - LocaleInfoPlugin
/**
 A plugin created to append locale information to the message context.
 */
final class LocaleInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        guard let localeInfo = self.preparedLocaleInfo else { return event }
        return event.addToContext(info: ["locale": localeInfo])
    }
    
    private var preparedLocaleInfo: String? {
        if #available(iOS 16.0, *) {
            let locale = Locale.current
            guard let languageCode = locale.language.languageCode?.identifier, let regionCode = locale.region?.identifier else { return nil }
            return "\(languageCode)-\(regionCode)"
        } else {
            let locale = Locale.current
            guard let languageCode = locale.languageCode, let regionCode = locale.regionCode else { return nil }
            return "\(languageCode)-\(regionCode)"
        }
    }
}
