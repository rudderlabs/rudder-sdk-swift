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
 existing lists. An inactive state never takes a runtime update. `active` and
 `provider` are load-time settings and are never modified at runtime.

 Validating the update itself belongs to `Analytics.setConsent`, which refuses one carrying no
 consent IDs at all and warns. Repeating that check here would leave two copies of one rule free
 to drift apart — and `setConsent` opens the device-mode holds before dispatching, so a divergence
 would strand those against a decision that never landed.
 */
struct SetConsentAction: StateAction {
    typealias T = ConsentManagement
    private let options: ConsentManagementOptions
    
    init(options: ConsentManagementOptions) {
        self.options = options
    }
    
    func reduce(currentState: ConsentManagement) -> ConsentManagement {
        guard currentState.active else { return currentState }

        let allowed = ConsentManagement.normalized(options.allowedConsentIds)
        let denied = ConsentManagement.normalized(options.deniedConsentIds)

        var newState = currentState
        newState.allowedConsentIds = allowed
        newState.deniedConsentIds = denied
        return newState
    }
}
