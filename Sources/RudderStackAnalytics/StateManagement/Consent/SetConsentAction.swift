//
//  SetConsentAction.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Foundation

// MARK: - SetConsentAction
/**
 An action that replaces the consent lists in `ConsentManagement`.
 
 This is a full replacement, not a merge: the supplied lists overwrite both
 existing lists. Empty options clear everything and revert the state to
 uninitialized (fail-open), matching the JS SDK behavior. `enabled` and
 `provider` are load-time settings and are never modified at runtime.
 */
struct SetConsentAction: StateAction {
    typealias T = ConsentManagement
    private let options: ConsentManagementOptions
    
    init(options: ConsentManagementOptions) {
        self.options = options
    }
    
    func reduce(currentState: ConsentManagement) -> ConsentManagement {
        var newState = currentState
        newState.allowedConsentIds = ConsentManagement.normalized(options.allowedConsentIds)
        newState.deniedConsentIds = ConsentManagement.normalized(options.deniedConsentIds)
        newState.initialized = !(newState.allowedConsentIds.isEmpty && newState.deniedConsentIds.isEmpty)
        return newState
    }
}
