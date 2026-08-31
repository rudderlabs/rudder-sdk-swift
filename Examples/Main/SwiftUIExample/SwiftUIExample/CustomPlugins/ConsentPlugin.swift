//
//  ConsentPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 31/08/26.
//

import Foundation
import RudderStackAnalytics

// MARK: - ConsentPlugin
/**
 A sample pattern for bridging a Consent Management Platform into the SDK. This is example
 code, not SDK API — copy it into your project and adapt it to your CMP.
 
 The plugin never modifies the event context. The SDK owns `context.consentManagement` and
 stamps it from the state recorded by `setConsent(_:)`; a plugin writing that key is
 overwritten by the SDK and logs a warning.
 
 ## Usage:
 ```swift
 let plugin = ConsentPlugin(provider: myCmpAdapter)
 analytics.add(plugin: plugin)
 Adding the plugin pushes whatever the CMP already knows, then keeps the SDK in sync as the
 user changes their choices.
 */

final class ConsentPlugin: Plugin {
    /* Never intercepts events — it only reacts to the CMP and calls setConsent(_:). */
    var pluginType: PluginType = .utility
    
    /** The analytics client instance, set during setup. */
    var analytics: Analytics?
    
    private let provider: ConsentCategoryProvider
    
    /** Creates a new ConsentPlugin backed by the given CMP adapter. */
    init(provider: ConsentCategoryProvider) {
        self.provider = provider
    }
    
    /** Subscribes to the CMP and pushes its current choices to the SDK. */
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.provider.onConsentChanged = { [weak self] in
            self?.pushCurrentConsent()
        }
        self.pushCurrentConsent()
    }
    
    /** Stops listening to the CMP. */
    func teardown() {
        self.provider.onConsentChanged = nil
    }
    
    /**
     Hands the CMP's current choices to the SDK. The new lists fully replace the previous
     consent state and apply from the next event onward.
     */
    func pushCurrentConsent() {
        let options = ConsentManagementOptions(
            allowedConsentIds: self.provider.allowedConsentIds,
            deniedConsentIds: self.provider.deniedConsentIds
        )
        self.analytics?.setConsent(options)
    }
}

// MARK: - ConsentCategoryProvider
/**
 The slice of a Consent Management Platform that `ConsentPlugin` depends on.
 
 Adapt this to whichever CMP the app uses — the plugin needs only the two ID lists and a
 notification for when the user changes their choices.
 */
protocol ConsentCategoryProvider: AnyObject {
    /** Consent category IDs the user has granted. */
    var allowedConsentIds: [String] { get }
    
    /** Consent category IDs the user has denied. */
    var deniedConsentIds: [String] { get }
    
    /** Invoked by the CMP whenever the user's choices change. */
    var onConsentChanged: (() -> Void)? { get set }
}
