//
//  UpdateSourceConfigAction.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 16/09/25.
//

import Foundation

// MARK: - UpdateSourceConfigAction
/**
 Represents an action that updates the source configuration in the application's state.
 */

struct UpdateSourceConfigAction: StateAction {
    typealias T = SourceConfig
    
    private let updatedSourceConfig: SourceConfig
    
    init(updatedSourceConfig: SourceConfig) {
        self.updatedSourceConfig = updatedSourceConfig
    }
    
    func reduce(currentState: SourceConfig) -> SourceConfig {
        return updatedSourceConfig
    }
}
