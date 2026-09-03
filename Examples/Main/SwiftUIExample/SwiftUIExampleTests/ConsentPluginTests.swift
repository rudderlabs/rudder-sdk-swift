//
//  ConsentPluginTests.swift
//  SwiftUIExampleAppTests
//
//  Created by Satheesh Kannan on 31/08/26.
//

import Testing
import RudderStackAnalytics
@testable import SwiftUIExampleApp

// MARK: - ConsentPluginTests
struct ConsentPluginTests {

    private var testConfiguration: Configuration {
        return Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
    }

    @Test
    func test_whenPluginIsAddedThenCurrentConsentIsPushed() {
        given("A ConsentPlugin backed by a spy CMP") {
            let provider = SpyConsentProvider()
            let plugin = ConsentPlugin(provider: provider)

            when("The plugin is set up") {
                plugin.setup(analytics: Analytics(configuration: self.testConfiguration))

                then("It pushes the current state once and subscribes to the CMP") {
                    #expect(plugin.pluginType == .utility)
                    #expect(provider.pushCount == 1)
                    #expect(provider.onConsentChanged != nil)
                }
            }
        }
    }

    @Test
    func test_whenCmpChangesThenConsentIsPushedAgain() {
        given("A ConsentPlugin already set up") {
            let provider = SpyConsentProvider()
            let plugin = ConsentPlugin(provider: provider)
            plugin.setup(analytics: Analytics(configuration: self.testConfiguration))

            when("The user changes their choices in the CMP") {
                provider.simulateConsentChange(allowed: ["analytics"], denied: ["marketing"])

                then("The plugin pushes the new state") {
                    #expect(provider.pushCount == 2)
                }
            }
        }
    }

    @Test
    func test_whenTornDownThenCmpChangesAreIgnored() {
        given("A ConsentPlugin already set up") {
            let provider = SpyConsentProvider()
            let plugin = ConsentPlugin(provider: provider)
            plugin.setup(analytics: Analytics(configuration: self.testConfiguration))
            let countAfterSetup = provider.pushCount

            when("The plugin is torn down and the CMP changes afterwards") {
                plugin.teardown()
                provider.simulateConsentChange(allowed: ["analytics"], denied: [])

                then("It unsubscribes and pushes nothing further") {
                    #expect(provider.onConsentChanged == nil)
                    #expect(provider.pushCount == countAfterSetup)
                }
            }
        }
    }

    @Test
    func test_whenInterceptingThenEventIsUnchanged() {
        given("A ConsentPlugin and an event carrying its own context") {
            let plugin = ConsentPlugin(provider: SpyConsentProvider())
            let event = MockEvent()
            event.context = [
                "existing": [
                    "sample_key": "sample_value"
                ]
            ].codableWrapped

            when("The event passes through the plugin") {
                let result = plugin.intercept(event: event)

                then("The context is untouched — the SDK owns consentManagement") {
                    #expect(result != nil)

                    guard let context = result?.context?.rawDictionary else {
                        #expect(Bool(false), "Context not available or not of expected type")
                        return
                    }
                    #expect(context["consentManagement"] == nil)
                    #expect(context["existing"] != nil)
                }
            }
        }
    }
}

// MARK: - SpyConsentProvider
/**
 A stand-in Consent Management Platform that records how many times the plugin read its
 allowed-consent list. Reads stand in for pushes: `setConsent` writes into SDK state the
 example target cannot read back, so the provider is the observable seam.
 */
final class SpyConsentProvider: ConsentCategoryProvider {
    private(set) var pushCount = 0
    private var storedAllowed: [String]
    private var storedDenied: [String]

    var allowedConsentIds: [String] {
        self.pushCount += 1
        return self.storedAllowed
    }

    var deniedConsentIds: [String] { self.storedDenied }

    var onConsentChanged: (() -> Void)?

    init(allowed: [String] = ["marketing"], denied: [String] = ["advertising"]) {
        self.storedAllowed = allowed
        self.storedDenied = denied
    }

    /** Mimics the user changing their choices in the CMP. */
    func simulateConsentChange(allowed: [String], denied: [String]) {
        self.storedAllowed = allowed
        self.storedDenied = denied
        self.onConsentChanged?()
    }
}
