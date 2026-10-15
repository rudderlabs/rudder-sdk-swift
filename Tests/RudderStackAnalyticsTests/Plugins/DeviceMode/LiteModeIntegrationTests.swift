//
//  LiteModeIntegrationTests.swift
//  RudderStackAnalyticsTests
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("LiteMode Integration Tests")
struct LiteModeIntegrationTests {

    var analytics: Analytics
    let destinationKey = "Lite Destination"

    init() {
        let mockConfiguration = MockProvider.createMockConfiguration()
        mockConfiguration.flushPolicies = []

        self.analytics = Analytics(configuration: mockConfiguration)
    }

    // MARK: - Standard Lite Integration

    @Test("Given a lite integration that holds the app's instance and a pending callback, When two configs arrive, Then create runs once, the callback gets the app's instance, and the second config runs update")
    func liteIntegrationCreatesOnceThenUpdates() throws {
        let controller = try #require(analytics.integrationsController)
        let appInstance = MockDestination(config: [:])
        let mockPlugin = makeLitePlugin(holding: appInstance)
        var results: [(instance: Any?, result: DestinationResult)] = []

        mockPlugin.onDestinationReady { instance, result in
            results.append((instance, result))
        }
        #expect(results.isEmpty, "A lite instance alone must not answer the callback before create runs.")

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
        #expect(!mockPlugin.updateCalled)
        #expect(results.count == 1)
        #expect(isSuccess(results.first?.result))
        #expect(results.first?.instance as AnyObject? === appInstance)

        var lateResult: DestinationResult?
        mockPlugin.onDestinationReady { _, result in lateResult = result }
        #expect(isSuccess(lateResult))

        mockPlugin.resetCallFlags()
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(!mockPlugin.createCalled)
        #expect(mockPlugin.updateCalled)
        #expect(mockPlugin.getDestinationInstance() as AnyObject? === appInstance)
    }

    @Test("Given a ready lite integration, When an event is intercepted, Then the integration delivers it")
    func liteIntegrationDeliversEvents() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        _ = mockPlugin.intercept(event: TrackEvent(event: "lite-event").updateEventData())

        #expect(mockPlugin.receivedTrackEventNames == ["lite-event"])
    }

    @Test("Given a lite integration with a pending callback, When the first config disables the destination, Then the callback gets failure and create does not run")
    func liteIntegrationDisabledInFirstConfig() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        var callbackResult: DestinationResult?

        mockPlugin.onDestinationReady { _, result in callbackResult = result }
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: false), integration: mockPlugin)

        #expect(isFailure(callbackResult))
        #expect(!mockPlugin.createCalled)
        #expect(mockPlugin.pluginStore?.hasCreateSucceeded == false)
    }

    @Test("Given a lite integration whose create throws, When the next config arrives, Then the callback gets failure and create runs again")
    func liteIntegrationRetriesCreateAfterFailure() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        mockPlugin.createThrowsError = MockIntegrationError.createFailed
        var callbackResult: DestinationResult?

        mockPlugin.onDestinationReady { _, result in callbackResult = result }
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
        #expect(isFailure(callbackResult))

        mockPlugin.resetCallFlags()
        mockPlugin.createThrowsError = nil
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
        #expect(!mockPlugin.updateCalled)
        #expect(mockPlugin.pluginStore?.isDestinationReady == true)
    }

    // MARK: - Custom Integration

    @Test("Given a custom integration that holds an instance before the first config, When the config arrives, Then create runs and the pending callback gets success")
    func customIntegrationWithInstanceBecomesReady() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = MockCustomIntegrationPlugin(key: destinationKey)
        mockPlugin.setDestinationInstance(MockDestination(config: [:]))
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        var callbackResult: DestinationResult?

        mockPlugin.onDestinationReady { _, result in callbackResult = result }
        #expect(callbackResult == nil)

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
        #expect(isSuccess(callbackResult))
    }

    // MARK: - Objective-C Adapter

    @Test("Given Objective-C integrations with and without isLiteMode, When the adapter reads isLiteMode, Then it reports the implemented value or false")
    func objcAdapterReportsLiteMode() {
        #expect(MockObjCIntegration().integration.isLiteMode == false)
        #expect(MockLiteObjCIntegration().integration.isLiteMode == true)
    }
}

// MARK: - Helpers

extension LiteModeIntegrationTests {

    private func makeLitePlugin(holding instance: Any) -> MockStandardIntegrationPlugin {
        let mockPlugin = MockStandardIntegrationPlugin(key: destinationKey)
        mockPlugin.isLiteMode = true
        mockPlugin.setDestinationInstance(instance)
        analytics.integrationsController?.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        return mockPlugin
    }

    private func isSuccess(_ result: DestinationResult?) -> Bool {
        if case .success = result { return true }
        return false
    }

    private func isFailure(_ result: DestinationResult?) -> Bool {
        if case .failure = result { return true }
        return false
    }

    private func makeSourceConfig(isDestinationEnabled: Bool) -> SourceConfig {
        let destination = Destination(
            destinationId: "dest-1",
            destinationName: destinationKey,
            isDestinationEnabled: isDestinationEnabled,
            destinationConfig: ["apiKey": AnyCodable("mock-api-key")],
            destinationDefinitionId: "def-1",
            destinationDefinition: DestinationDefinition(
                name: destinationKey,
                displayName: destinationKey
            ),
            updatedAt: "2026-01-01T00:00:00.000Z",
            shouldApplyDeviceModeTransformation: false,
            propagateEventsUntransformedOnError: true
        )

        return SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "source-id",
                sourceName: "source-name",
                writeKey: "write-key",
                isSourceEnabled: true,
                workspaceId: "workspace-id",
                updatedAt: "2026-01-01T00:00:00.000Z",
                metricConfig: MetricsConfig(),
                destinations: [destination]
            )
        )
    }
}

// MARK: - Objective-C Mocks

private final class MockObjCIntegration: NSObject, ObjCIntegrationPlugin {
    var pluginType: PluginType = .terminal
    var key: String = "objc_destination"

    func getDestinationInstance() -> Any? { nil }

    func createWithDestinationConfig(_ destinationConfig: [String: Any], error: NSErrorPointer) -> Bool { true }
}

private final class MockLiteObjCIntegration: NSObject, ObjCIntegrationPlugin {
    var pluginType: PluginType = .terminal
    var key: String = "objc_lite_destination"
    var isLiteMode: Bool { true }

    func getDestinationInstance() -> Any? { nil }

    func createWithDestinationConfig(_ destinationConfig: [String: Any], error: NSErrorPointer) -> Bool { true }
}
