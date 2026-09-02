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
 existing lists. An update carrying no consent IDs at all is rejected — the
 current state is returned unchanged. `enabled` and `provider` are load-time
 settings and are never modified at runtime.
 */
struct SetConsentAction: StateAction {
    typealias T = ConsentManagement
    private let options: ConsentManagementOptions
    
    init(options: ConsentManagementOptions) {
        self.options = options
    }
    
    func reduce(currentState: ConsentManagement) -> ConsentManagement {
        guard currentState.enabled else { return currentState }

        let allowed = ConsentManagement.normalized(options.allowedConsentIds)
        let denied = ConsentManagement.normalized(options.deniedConsentIds)
        
        guard !(allowed.isEmpty && denied.isEmpty) else { return currentState }

        var newState = currentState
        newState.allowedConsentIds = allowed
        newState.deniedConsentIds = denied
        newState.initialized = true
        return newState
    }
}
