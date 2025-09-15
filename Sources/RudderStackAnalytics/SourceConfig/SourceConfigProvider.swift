//
//  SourceConfigProvider.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 15/09/25.
//

import Foundation

final class SourceConfigProvider {
    private weak var analytics: Analytics?
    private let sourceConfigState: StateImpl<SourceConfig>
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.sourceConfigState = analytics.sourceConfigState
    }
    
    func fetchCachedConfigAndNotifyObservers() {}
    
    func refreshConfigAndNotifyObservers() {}
}
