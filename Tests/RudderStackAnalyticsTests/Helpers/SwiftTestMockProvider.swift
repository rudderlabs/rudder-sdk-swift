import Testing
import Foundation
@testable import RudderStackAnalytics

// MARK: - MockProvider for Swift Testing
final class SwiftTestMockProvider {
    private init() {}
    
    static var mockWriteKey: String {
        return "test-write-key-\(UUID().uuidString)"
    }
    
    static var mockDataPlaneUrl: String {
        return "https://test.dataplane.com"
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
            writeKey: writeKey ?? mockWriteKey,
            dataPlaneUrl: dataPlaneUrl ?? mockDataPlaneUrl
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
                writeKey: mockWriteKey,
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

// MARK: - Unified Mock Plugin for Swift Testing
final class MockEventCapturePlugin: Plugin {
    var pluginType: PluginType
    weak var analytics: Analytics?
    
    // Tracking properties
    private(set) var setupCalled = false
    private(set) var executeCalled = false
    private(set) var shutdownCalled = false
    private(set) var capturedEvents: [Event] = []
    private let eventLock = NSLock()
    
    // Configuration properties for advanced testing
    var shouldFilterEvent = false
    var shouldModifyEvent = false
    var eventModifications: [String: Any] = [:]
    
    // MARK: - Initialization
    
    init(type: PluginType = .terminal, enableFiltering: Bool = false, enableModification: Bool = false) {
        self.pluginType = type
        self.shouldFilterEvent = enableFiltering
        self.shouldModifyEvent = enableModification
    }
    
    // MARK: - Plugin Protocol Methods
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        setupCalled = true
    }
    
    func intercept(event: any Event) -> (any Event)? {
        executeCalled = true
        
        // Always capture the event (before any filtering/modification)
        eventLock.lock()
        capturedEvents.append(event)
        eventLock.unlock()
        
        // Handle filtering
        if shouldFilterEvent {
            return nil
        }
        
        // Handle event modification
        if shouldModifyEvent {
            var modifiedEvent = event
            
            // Apply modifications based on event type
            if var trackEvent = modifiedEvent as? TrackEvent {
                var properties = trackEvent.properties?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    properties[key] = value
                }
                trackEvent.properties = CodableCollection(dictionary: properties)
                modifiedEvent = trackEvent
            } else if var screenEvent = modifiedEvent as? ScreenEvent {
                var properties = screenEvent.properties?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    properties[key] = value
                }
                screenEvent.properties = CodableCollection(dictionary: properties)
                modifiedEvent = screenEvent
            } else if var identifyEvent = modifiedEvent as? IdentifyEvent {
                var traits = identifyEvent.traits?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    traits[key] = value
                }
                identifyEvent.traits = CodableCollection(dictionary: traits)
                modifiedEvent = identifyEvent
            } else if var groupEvent = modifiedEvent as? GroupEvent {
                var traits = groupEvent.traits?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    traits[key] = value
                }
                groupEvent.traits = CodableCollection(dictionary: traits)
                modifiedEvent = groupEvent
            }
            
            return modifiedEvent
        }
        
        return event
    }
    
    func shutdown() {
        shutdownCalled = true
    }
    
    // MARK: - Event Access Methods
    
    var lastProcessedEvent: Event? {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents.last
    }
    
    var receivedEvents: [Event] {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents
    }
    
    func getEventsOfType<T: Event>(_ type: T.Type) -> [T] {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents.compactMap { $0 as? T }
    }
    
    func clearEvents() {
        eventLock.lock()
        capturedEvents.removeAll()
        eventLock.unlock()
    }
    
    var eventCount: Int {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents.count
    }
    
    // MARK: - Configuration Methods
    
    func enableFiltering() {
        shouldFilterEvent = true
    }
    
    func disableFiltering() {
        shouldFilterEvent = false
    }
    
    func enableModification(with modifications: [String: Any] = [:]) {
        shouldModifyEvent = true
        eventModifications = modifications
    }
    
    func disableModification() {
        shouldModifyEvent = false
        eventModifications = [:]
    }
    
    func setEventModifications(_ modifications: [String: Any]) {
        eventModifications = modifications
    }
}

extension MockEventCapturePlugin {
    // Generic version (wait for specific type)
    @discardableResult
    func waitForEvents<T: Event>(_ type: T.Type, count expectedCount: Int = 1, timeout: TimeInterval? = nil) async -> [T] {
        let start = Date()
        
        while true {
            let events = getEventsOfType(type)
            if events.count >= expectedCount {
                return events
            }
            if let timeout, Date().timeIntervalSince(start) > timeout {
                return events
            }
            await Task.yield()
        }
    }

    // Non-generic version (wait for all events)
    @discardableResult
    func waitForEvents(count expectedCount: Int = 1, timeout: TimeInterval? = nil) async -> [Event] {
        let start = Date()
        
        while true {
            let events = receivedEvents
            if events.count >= expectedCount {
                return events
            }
            if let timeout, Date().timeIntervalSince(start) > timeout {
                return events
            }
            await Task.yield()
        }
    }
}

// MARK: - Test Helpers
extension SwiftTestMockProvider {
    
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
    
    func runAfter(_ seconds: Double, block: @escaping () async -> Void) async {
        // Suspend the current task for the specified duration
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        
        // Execute the block after the delay
        await block()
    }
    
    static var sourceConfiguration: SourceConfig? {
        guard let mockJson = SwiftTestMockProvider.readJson(from: "mock_source_config")?.trimmed, let mockJsonData = mockJson.utf8Data else { return nil }
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
            let json = responseCode == 200 ? (SwiftTestMockProvider.sourceConfigurationDictionary ?? [:]) : ["error": "Server error"]
            let data = try JSONSerialization.data(withJSONObject: json)
            return (responseCode, data, ["Content-Type": "application/json"])
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    static func prepareMockDataPlaneSession(with responseCode: Int) -> URLSession {
        MockURLProtocol.requestHandler = { _ in
            let json = responseCode == 200 ? ["Success": "Ok"] : ["error": "Server error"]
            let data = try JSONSerialization.data(withJSONObject: json)
            return (responseCode, data, ["Content-Type": "application/json"])
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

// MARK: - MockLogger for capturing log output
class SwiftMockLogger: Logger {
    var logs: [(level: String, message: String)] = []
    
    func verbose(log: String) {
        logs.append(("VERBOSE", log))
    }
    
    func debug(log: String) {
        logs.append(("DEBUG", log))
    }
    
    func info(log: String) {
        logs.append(("INFO", log))
    }
    
    func warn(log: String) {
        logs.append(("WARN", log))
    }
    
    func error(log: String, error: Error?) {
        if let error {
            logs.append(("ERROR", "\(log) - \(error.localizedDescription)"))
        } else {
            logs.append(("ERROR", log))
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func hasLog(level: String, containing message: String) -> Bool {
        return logs.contains { $0.level == level && $0.message.contains(message) }
    }
    
    func logCount(for level: String) -> Int {
        return logs.filter { $0.level == level }.count
    }
}

// MARK: - JSON Helper Functions
extension SwiftTestMockProvider {
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
}

// MARK: - MockAnalytics
class MockAnalytics: Analytics {
    var isFlushed: Bool = false
    
    init() {
        let config = Configuration(writeKey: "_sample_write_key_", dataPlaneUrl: "_sample_data_plane_url_")
        super.init(configuration: config)
    }
    
    override func flush() {
        self.isFlushed = true
    }
}
