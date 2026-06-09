# Swift Integration Test Scaffold

## Directory Layout

```
Tests/
  RudderIntegration<Name>Tests/
    <Name>IntegrationTests.swift    -- Main test file
    <Name>TestUtils.swift           -- Mock adapter + test data
```

## Dependencies

The test target in `Package.swift` depends on the library target, and may also need the third-party SDK when adapter protocol methods use SDK-owned types (so the mock adapter compiles):
```swift
.testTarget(
    name: "RudderIntegration<Name>Tests",
    dependencies: [
        "RudderIntegration<Name>",
        // "<ThirdPartySDKProduct>" // add only when adapter signatures reference SDK types
    ]
)
```

## Framework: Swift Testing

All tests use the Swift Testing framework — **not** XCTest.

```swift
import Testing
import Foundation
import RudderStackAnalytics
import <ThirdPartySDK>      // Only if needed for types
@testable import RudderIntegration<Name>
```

## Test File Template: `<Name>IntegrationTests.swift`

```swift
import Testing
import Foundation
import RudderStackAnalytics
@testable import RudderIntegration<Name>

@Suite(.serialized)
class <Name>IntegrationTests {

    // MARK: - Test Properties

    private var mockAdapter: Mock<Name>Adapter!
    private var integration: <Name>Integration!
    private var mockAnalytics: Analytics!

    // MARK: - Setup and Teardown

    init() {
        self.mockAdapter = Mock<Name>Adapter()
        self.integration = <Name>Integration(adapter: mockAdapter)

        let config = Configuration(
            writeKey: "test-write-key",
            dataPlaneUrl: "https://test.rudderstack.com"
        )
        self.mockAnalytics = Analytics(configuration: config)
        self.integration.analytics = mockAnalytics
    }

    deinit {
        self.mockAdapter = nil
        self.integration = nil
        self.mockAnalytics = nil
    }

    // MARK: - Helper Methods

    private func setupWithDefaultConfig() throws {
        try integration.create(destinationConfig: <Name>TestData.validConfig)
    }

    private func setupWithConfig(_ config: [String: Any]) throws {
        try integration.create(destinationConfig: config)
    }

    // MARK: - Create Tests

    @Test("given valid config, when create is called, then destination SDK is initialized")
    func testCreateWithValidConfig() throws {
        try setupWithDefaultConfig()

        #expect(mockAdapter.initCalls.count == 1)
        // Verify config was parsed correctly
    }

    @Test("given initialized integration, when getDestinationInstance is called, then returns instance")
    func testGetDestinationInstanceWhenInitialized() throws {
        try setupWithDefaultConfig()
        let instance = integration.getDestinationInstance()

        #expect(instance != nil)
    }

    @Test("given uninitialized integration, when getDestinationInstance is called, then returns nil")
    func testGetDestinationInstanceWhenNotInitialized() {
        let instance = integration.getDestinationInstance()

        #expect(instance == nil)
    }

    // MARK: - Identify Tests
    // Add tests for each event method...

    @Test("given initialized integration, when identify is called with userId, then user is identified")
    func testIdentifyWithUserId() throws {
        try setupWithDefaultConfig()
        let event = <Name>TestData.createIdentifyEvent(userId: "test_user")

        integration.identify(payload: event)

        // Verify adapter calls
    }

    // MARK: - Track Tests

    @Test("given initialized integration, when track is called with event, then event is logged")
    func testTrackWithEvent() throws {
        try setupWithDefaultConfig()
        let event = <Name>TestData.createTrackEvent(
            name: "Test Event",
            properties: ["key": "value"]
        )

        integration.track(payload: event)

        // Verify adapter calls
    }

    // MARK: - Reset Tests

    @Test("given initialized integration, when reset is called, then state is cleared")
    func testReset() throws {
        try setupWithDefaultConfig()

        integration.reset()

        // Verify adapter reset calls
    }
}
```

## Test Utilities Template: `<Name>TestUtils.swift`

```swift
import Foundation
import RudderStackAnalytics
@testable import RudderIntegration<Name>

// MARK: - Mock Adapter

class Mock<Name>Adapter: <Name>Adapter {

    // Track all calls for verification
    var initCalls: [(/* params */)] = []
    var isInitialized = false
    // Add tracking arrays for each adapter method...

    // Implement each adapter protocol method:
    // 1. Record the call in the tracking array
    // 2. Return a sensible default

    func getDestinationInstance() -> Any? {
        return isInitialized ? "Mock<Name>Instance" : nil
    }

    // MARK: - Helper

    func reset() {
        isInitialized = false
        initCalls.removeAll()
        // Reset all tracking arrays...
    }
}

// MARK: - Test Data

struct <Name>TestData {

    static var validConfig: [String: Any] {
        [
            // Minimum valid config for the integration
        ]
    }

    static var invalidConfig: [String: Any] {
        [
            // Config missing required fields
        ]
    }
}

// MARK: - Event Creation Helpers

extension <Name>TestData {

    static func createIdentifyEvent(
        userId: String? = "test_user",
        traits: [String: Any]? = nil
    ) -> IdentifyEvent {
        var event = IdentifyEvent()
        event.userId = userId

        if let traits = traits {
            var context: [String: Any] = [:]
            context["traits"] = traits
            event.context = context.mapValues { AnyCodable($0) }
        }

        return event
    }

    static func createTrackEvent(
        name: String,
        properties: [String: Any]? = nil
    ) -> TrackEvent {
        return TrackEvent(event: name, properties: properties)
    }

    static func createScreenEvent(
        name: String,
        properties: [String: Any]? = nil
    ) -> ScreenEvent {
        return ScreenEvent(screenName: name, properties: properties)
    }
}
```

## Test Naming Convention

Use the Given/When/Then pattern in `@Test` descriptions:
```swift
@Test("given <precondition>, when <action>, then <expected outcome>")
```

Examples:
- `@Test("given valid config, when create is called, then SDK is initialized")`
- `@Test("given identify with userId, when identify is called, then user ID is set")`
- `@Test("given track with properties, when track is called, then properties are forwarded")`
- `@Test("given uninitialized integration, when getDestinationInstance is called, then returns nil")`

## Mock Adapter Pattern

The mock adapter pattern for Swift integrations:

1. **One tracking array per adapter method** — use tuples for methods with multiple parameters:
   ```swift
   var logEventCalls: [(name: String, parameters: [String: Any]?)] = []
   ```

2. **Boolean flags for state** — `isInitialized`, `shouldFailInit`, etc.

3. **`reset()` method** — clears all tracking arrays and flags for test isolation.

4. **Return sensible defaults** — `getDestinationInstance()` returns a string identifier when initialized, `nil` otherwise.

## Verification Patterns

```swift
// Verify a method was called
#expect(mockAdapter.logEventCalls.count == 1)

// Verify call parameters
#expect(mockAdapter.logEventCalls[0].name == "expected_event")

// Verify a method was NOT called
#expect(mockAdapter.logEventCalls.isEmpty)

// Verify optional value
#expect(mockAdapter.logEventCalls[0].parameters != nil)

// Verify specific parameter value
#expect(mockAdapter.logEventCalls[0].parameters?["key"] as? String == "value")
```

## Test Data Best Practices

- Use `static var` for config dictionaries (computed properties, fresh each access)
- Use `static func` for event creation (parameterized)
- Include both valid and invalid configs
- Include edge case data: empty strings, nil values, missing keys
- Use realistic but obviously fake data (e.g., `"test-api-key-123"`, `"test_user_123"`)
