//
//  SetUserIdTraitsAndExternalIdsAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/01/25.
//

import Foundation

struct SetUserIdTraitsAndExternalIdsAction: StateAction {
    typealias T = UserIdentity
    
    private let userId: String
    private let traits: [String: Any]
    private let externalIds: [ExternalId]
    private let analytics: AnalyticsClient
    
    init(userId: String, traits: [String : Any], externalIds: [ExternalId], analytics: AnalyticsClient) {
        self.userId = userId
        self.traits = traits
        self.externalIds = externalIds
        self.analytics = analytics
    }
    
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.userId = userId
        
        let isUserIdChanged = currentState.userId != userId
        
        if isUserIdChanged {
            currentState.resetUserIdTraitsAndExternalIds(self.analytics.configuration.storage)
        
            newState.traits = traits
            newState.externalIds = externalIds
        } else {
            newState.traits = currentState.traits + self.traits
            newState.externalIds = currentState.externalIds.mergeWithHigherPriorityTo(self.externalIds)
        }
        
        return newState
    }
}
