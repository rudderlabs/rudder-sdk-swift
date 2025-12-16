//
//  MockProvider.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

// MARK: - MockConstant
enum MockConstant {
    static var mockDataPlaneUrl: String = "https://test.dataplane.com"
    static var mockWriteKey: String { "test-write-key-\(UUID().uuidString)" }
}

// MARK: - MockProvider
final class MockProvider {
    private init() {
        /* Default implementation (no-op) */
    }
    
    static func createMockAnalytics(
        storage: Storage = MockStorage(),
        sessionConfig: SessionConfiguration? = nil
    ) -> Analytics {
        let config = createMockConfiguration(storage: storage)
        
        if let sessionConfig = sessionConfig {
            config.sessionConfiguration = sessionConfig
        }
        
        return Analytics(configuration: config)
    }
    
    static func createMockConfiguration(
        writeKey: String? = nil,
        dataPlaneUrl: String? = nil,
        storage: Storage = MockStorage()
    ) -> Configuration {
        let config = Configuration(
            writeKey: writeKey ?? MockConstant.mockWriteKey,
            dataPlaneUrl: dataPlaneUrl ?? MockConstant.mockDataPlaneUrl
        )
        config.storageMode = storage.eventStorageMode
        config.storage = storage
        return config
    }
    
    // MARK: - Mock Events
    static var mockTrackEvent: TrackEvent {
        return TrackEvent(
            event: "Test Track Event",
            properties: [
                "property1": "value1",
                "property2": 123,
                "property3": true
            ],
            options: RudderOption()
        )
    }
    
    static var mockScreenEvent: ScreenEvent {
        return ScreenEvent(
            screenName: "Test Screen",
            category: "Test Category",
            properties: ["screen_property": "test_value"],
            options: RudderOption()
        )
    }
    
    static var mockIdentifyEvent: IdentifyEvent {
        return IdentifyEvent(options: RudderOption())
    }
    
    static var mockGroupEvent: GroupEvent {
        return GroupEvent(
            groupId: "test-group-123",
            traits: ["company": "Test Company"],
            options: RudderOption()
        )
    }
    
    static var mockAliasEvent: AliasEvent {
        return AliasEvent(
            previousId: "old-user-id",
            options: RudderOption()
        )
    }
    
    // MARK: - Mock Session Configuration
    static var mockSessionConfiguration: SessionConfiguration {
        let config = SessionConfiguration()
        config.automaticSessionTracking = true
        config.sessionTimeoutInMillis = 300000 // 5 minutes
        return config
    }
    
    static var mockManualSessionConfiguration: SessionConfiguration {
        let config = SessionConfiguration()
        config.automaticSessionTracking = false
        config.sessionTimeoutInMillis = 600000 // 10 minutes
        return config
    }
    
    // MARK: - Mock Source Config
    static var mockSourceConfig: SourceConfig {
        let destinations = [
            Destination(
                destinationId: "test-dest-id-1",
                destinationName: "Test Destination 1",
                isDestinationEnabled: true,
                destinationConfig: [:],
                destinationDefinitionId: "test-dest-def-id-1",
                destinationDefinition: DestinationDefinition(
                    name: "Test Destination Definition",
                    displayName: "Test Destination Display"
                ),
                updatedAt: "2024-10-15T10:00:00Z",
                shouldApplyDeviceModeTransformation: true,
                propagateEventsUntransformedOnError: false
            )
        ]
        
        return SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "test-source-id",
                sourceName: "Test Source",
                writeKey: MockConstant.mockWriteKey,
                isSourceEnabled: true,
                workspaceId: "test-workspace-id",
                updatedAt: "2024-10-15T10:00:00Z",
                metricConfig: MetricsConfig(),
                destinations: destinations
            )
        )
    }
    
    // MARK: - Mock User Identity
    static var mockUserIdentity: UserIdentity {
        return UserIdentity(
            anonymousId: "test-anon-456", userId: "test-user-123"
        )
    }
}

// MARK: - Test Helpers
extension MockProvider {
    
    static func setupMockURLSession() {
        URLProtocol.registerClass(MockURLProtocol.self)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        HttpNetwork.session = URLSession(configuration: config)
    }
    
    static func teardownMockURLSession() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        let config = URLSessionConfiguration.ephemeral
        HttpNetwork.session = URLSession(configuration: config)
    }
    
    static var sourceConfiguration: SourceConfig? {
        guard let mockJson = MockProvider.readJson(from: "mock_source_config")?.trimmed, let mockJsonData = mockJson.utf8Data else { return nil }
        do {
            let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: mockJsonData)
            return sourceConfig
        } catch {
            print("Error parsing JSON: \(error)")
            return nil
        }
    }
    
    static var sourceConfigurationDictionary: [String: Any]? {
        guard let sourceConfig = sourceConfiguration else { return nil }
        return sourceConfig.dictionary
    }
    
    static func prepareMockSessionConfigSession(with responseCode: Int) -> URLSession {
        MockURLProtocol.requestHandler = { _ in
            let json = responseCode == 200 ? (MockProvider.sourceConfigurationDictionary ?? [:]) : ["error": "Server error"]
            let data = try JSONSerialization.data(withJSONObject: json)
            return (responseCode, data, ["Content-Type": "application/json"])
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

// MARK: - JSON Helper Functions
extension MockProvider {
    static func readJson(from file: String) -> String? {
        var bundles = [
            Bundle(for: MockProvider.self),
            Bundle.main,
        ]
        
        // Try to add Bundle.module if available (Swift Package Manager)
#if SWIFT_PACKAGE
        bundles.insert(Bundle.module, at: 0)
#endif
        
        for bundle in bundles {
            if let fileUrl = bundle.url(forResource: file, withExtension: "json"),
               let data = try? Data(contentsOf: fileUrl) {
                return data.jsonString
            }
        }
        return nil
    }
    
    static func resetDynamicValues(_ event: inout Event) {
        event.messageId = "<message-id>"
        event.anonymousId = "<anonymous-id>"
        event.originalTimestamp = "<original-timestamp>"
    }
}

// MARK: - MockProvider(Extension)
extension MockProvider {
    struct SampleEventName {
        private init() {
            /* Default implementation (no-op) */
        }
        static let track = "Sample_Track_Event"
        static let screen = "Sample_Screen_Event"
        static let group = "Sample_Group_Event"
    }
    
    static var sampleEventproperties: [String: Any] {
        let stringValue = "String value"
        
        return [
            "key-1": stringValue,
            "key-2": 123,
            "key-3": true,
            "key-4": 123.456,
            "key-5": [
                "key-6": stringValue,
                "key-7": 123,
                "key-8": true,
                "key-9": 123.456
            ],
            "key-10": [
                stringValue,
                123,
                true,
                123.456
            ],
            "key-11": [:]
        ]
    }
    
    static let sampleEventIntegrations: [String: Bool] = [
        "Amplitude": true,
        "Firebase": true,
        "Braze": false
    ]
}

// MARK: - String(Extension)
extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Run After

func runAfter(_ seconds: Double, block: @escaping () async -> Void) async {
    // Suspend the current task for the specified duration
    let nanoseconds = UInt64(seconds * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
    
    // Execute the block after the delay
    await block()
}
