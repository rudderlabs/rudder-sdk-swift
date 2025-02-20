//
//  LocaleInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import Foundation

// MARK: - LocaleInfoPlugin
/**
 A plugin created to append locale information to the event context.
 */
final class LocaleInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let localeInfo = self.preparedLocaleInfo else { return event }
        return event.addToContext(info: ["locale": localeInfo])
    }
    
    private var preparedLocaleInfo: String? {
        let locale = Locale.current
        let languageCode: String?
        let regionCode: String?
        
        if #available(iOS 16.0, *) {
            languageCode = locale.language.languageCode?.identifier
            regionCode = locale.region?.identifier
        } else {
            languageCode = locale.languageCode
            regionCode = locale.regionCode
        }
        
        guard let language = languageCode, let region = regionCode else { return nil }
        return "\(language)-\(region)"
    }
}
