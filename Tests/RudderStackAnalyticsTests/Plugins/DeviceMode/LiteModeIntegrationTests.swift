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
        #expect(mockPlugin.pluginStore?.destinationState == .pendingCreate)
    }

    @Test("Given a ready lite integration, When the destination is disabled and enabled again, Then the SDK calls update and not create")
    func liteIntegrationUpdatesAfterPause() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: false), integration: mockPlugin)

        #expect(mockPlugin.pluginStore?.isDestinationReady == false)

        mockPlugin.resetCallFlags()
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(!mockPlugin.createCalled)
        #expect(mockPlugin.updateCalled)
        #expect(mockPlugin.pluginStore?.isDestinationReady == true)
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

    @Test("Given a created integration, When it is removed and added again, Then the next config calls create again")
    func integrationIsCreatedAgainAfterReAdd() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        controller.remove(integration: mockPlugin)
        controller.add(integration: mockPlugin)
        mockPlugin.resetCallFlags()
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
        #expect(!mockPlugin.updateCalled)
        #expect(mockPlugin.pluginStore?.isDestinationReady == true)
    }

    @Test("Given a removed integration, When a config arrives, Then create does not run")
    func removedIntegrationIgnoresConfig() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))

        controller.remove(integration: mockPlugin)
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(!mockPlugin.createCalled)
        #expect(mockPlugin.pluginStore == nil)
    }

    @Test("Given a lite integration with a pending Obj-C callback, When the first config disables the destination, Then the callback gets an error that names the destination, and no instance")
    func objcCallbackReportsFailureForLiteIntegration() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        var callbackInstance: Any?
        var callbackError: NSError?
        ObjCAnalytics(analytics: analytics).onDestinationReady(forKey: destinationKey) { instance, error in
            callbackInstance = instance
            callbackError = error
        }

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: false), integration: mockPlugin)

        #expect(callbackError?.localizedDescription.contains(destinationKey) == true)
        #expect(callbackInstance == nil)
    }

    @Test("Given an integration that is removed while create runs, When it is added again, Then it gets no event until the next config calls create again")
    func removalDuringCreateDoesNotMarkReAddedIntegrationReady() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        mockPlugin.onCreate = { controller.remove(integration: mockPlugin) }

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)
        controller.add(integration: mockPlugin)
        controller.deliver(event: TrackEvent(event: "Before Create").updateEventData(), to: mockPlugin)

        #expect(mockPlugin.pluginStore?.destinationState == .pendingCreate)
        #expect(mockPlugin.receivedTrackEventNames.isEmpty)

        mockPlugin.resetCallFlags()
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
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

    @Test("Given a custom integration that holds no instance, When two configs arrive, Then create runs once and a later callback gets success")
    func customIntegrationWithoutInstanceCreatesOnce() throws {
        let controller = try #require(analytics.integrationsController)
        let plugin = NoInstanceCustomIntegration(key: destinationKey)
        controller.add(integration: plugin)
        plugin.setup(analytics: analytics)

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: plugin)
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: plugin)
        var callbackResult: DestinationResult?
        plugin.onDestinationReady { _, result in callbackResult = result }

        #expect(plugin.createCount == 1)
        #expect(isSuccess(callbackResult))
    }

    // MARK: - Late Callbacks

    @Test("Given a lite integration whose first config disables the destination, When a callback registers later, Then it gets the dashboard failure at once with no instance, and a later enabled config does not call it again")
    func lateCallbackGetsDashboardFailureBeforeCreate() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: false), integration: mockPlugin)
        var results: [(instance: Any?, result: DestinationResult)] = []

        mockPlugin.onDestinationReady { instance, result in results.append((instance, result)) }

        #expect(results.count == 1)
        #expect(results.first?.instance == nil)
        #expect(isDisabledError(results.first?.result))

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)

        #expect(mockPlugin.createCalled)
        #expect(results.count == 1)
    }

    @Test("Given a lite integration whose create throws, When the config arrives, Then the pending and late callbacks get the create error with no instance")
    func createFailureReachesPendingAndLateCallbacksWithoutInstance() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        mockPlugin.createThrowsError = MockIntegrationError.createFailed
        var pending: (instance: Any?, result: DestinationResult)?
        mockPlugin.onDestinationReady { instance, result in pending = (instance, result) }

        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)
        var late: (instance: Any?, result: DestinationResult)?
        mockPlugin.onDestinationReady { instance, result in late = (instance, result) }

        #expect(pending?.instance == nil)
        #expect(errorOf(pending?.result) as? MockIntegrationError == .createFailed)
        #expect(late?.instance == nil)
        #expect(errorOf(late?.result) as? MockIntegrationError == .createFailed)
    }

    @Test("Given a created integration that the dashboard then disables, When a callback registers, Then it gets the dashboard failure, not a generic one")
    func lateCallbackGetsRealReasonAfterCreate() throws {
        let controller = try #require(analytics.integrationsController)
        let mockPlugin = makeLitePlugin(holding: MockDestination(config: [:]))
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: true), integration: mockPlugin)
        controller.initDestination(sourceConfig: makeSourceConfig(isDestinationEnabled: false), integration: mockPlugin)
        var late: (instance: Any?, result: DestinationResult)?

        mockPlugin.onDestinationReady { instance, result in late = (instance, result) }

        #expect(late?.instance == nil)
        #expect(isDisabledError(late?.result))
    }
}

// MARK: - Helpers

extension LiteModeIntegrationTests {

    private func makeLitePlugin(holding instance: Any) -> MockStandardIntegrationPlugin {
        let mockPlugin = MockStandardIntegrationPlugin(key: destinationKey)
        mockPlugin.keepsPassedInstance = true
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

    private func errorOf(_ result: DestinationResult?) -> Error? {
        if case .failure(let error) = result { return error }
        return nil
    }

    private func isDisabledError(_ result: DestinationResult?) -> Bool {
        if case .destinationDisabled(let key) = errorOf(result) as? DestinationError { return key == destinationKey }
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

// MARK: - Mocks

private final class NoInstanceCustomIntegration: IntegrationPlugin {
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    var key: String
    private(set) var createCount = 0

    init(key: String) {
        self.key = key
    }

    func getDestinationInstance() -> Any? { nil }

    func create(destinationConfig: [String: Any]) throws {
        createCount += 1
    }
}
