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
    
    init(userId: String, traits: [String : Any], externalIds: [ExternalId]) {
        self.userId = userId
        self.traits = traits
        self.externalIds = externalIds
    }
    
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.userId = userId
        newState.traits = traits
        newState.externalIds = externalIds
        return newState
    }
}
