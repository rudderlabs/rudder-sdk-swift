//
//  DisableSourceConfigAction.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 23/09/25.
//

import Foundation

// MARK: - DisableSourceConfigAction
/**
 Action to disable a source configuration by setting its `isSourceEnabled` property to false.
 */
struct DisableSourceConfigAction: StateAction {
    
    typealias T = SourceConfig
    
    func reduce(currentState: SourceConfig) -> SourceConfig {
        var updatedSource = currentState.source
        updatedSource = RudderServerConfigSource(
            sourceId: updatedSource.sourceId,
            sourceName: updatedSource.sourceName,
            writeKey: updatedSource.writeKey,
            isSourceEnabled: false, // Disable the source
            workspaceId: updatedSource.workspaceId,
            updatedAt: updatedSource.updatedAt,
            metricConfig: updatedSource.metricConfig,
            destinations: updatedSource.destinations
        )
        
        return SourceConfig(source: updatedSource)
    }
}
