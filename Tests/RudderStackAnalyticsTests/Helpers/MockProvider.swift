//
//  MockProvider.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import XCTest
import Network
@testable import RudderStackAnalytics

// MARK: - MockProvider
final class MockProvider {
    private init() {}
    
    static var _mockWriteKey: String {
        return UUID().uuidString
    }
    static let keyValueStore: KeyValueStore = KeyValueStore(writeKey: _mockWriteKey)
    
    static var clientWithDiskStorage: Analytics {
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/b2b6be48-2c87-4ef8-b3a1-22e921f5eae6", flushPolicies: [])
        return Analytics(configuration: configuration)
    }
    
    static var clientWithMemoryStorage: Analytics {
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/b2b6be48-2c87-4ef8-b3a1-22e921f5eae6", flushPolicies: [])
        return Analytics(configuration: configuration)
    }
    
    static func clientWithSessionConfig(config: SessionConfiguration) -> Analytics{
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/b2b6be48-2c87-4ef8-b3a1-22e921f5eae6", flushPolicies: [], sessionConfiguration: config)
        return Analytics(configuration: configuration)
    }
}

// MARK: - MockProvider(Extension)
extension MockProvider {
    
    static let simpleTrackEvent: TrackEvent = {
        let event = TrackEvent(event: "Track_Event", properties: ["Property_1": "Value1"], options: RudderOption(customContext: ["custom_context": ["context_key": "context_value"]]))
        return event
    }()
    
    struct SampleEventName {
        private init() {}
        static let track = "Sample_Track_Event"
        static let screen = "Sample_Screen_Event"
        static let group = "Sample_Group_Event"
    }
    
    static let sampleEventproperties: [String: Any] = [
        "key-1": "String value",
        "key-2": 123,
        "key-3": true,
        "key-4": 123.456,
        "key-5": [
            "key-6": "String value",
            "key-7": 123,
            "key-8": true,
            "key-9": 123.456
        ],
        "key-10": [
            "String value",
            123,
            true,
            123.456
        ],
        "key-11": [:]
    ]
    
    static let sampleEventIntegrations: [String: Bool] = [
        "Amplitude": true,
        "Firebase": true,
        "Braze": false
    ]
}

extension MockProvider {
    
    static var sourceConfiguration: SourceConfig? {
        guard let mockJson = MockHelper.readJson(from: "mock_source_config")?.trimmed, let mockJsonData = mockJson.utf8Data else { return nil }
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
}

// MARK: - MockHelper
struct MockHelper {
    private init() {}
    
    static func seconds(from millis: Double) -> Double {
        return Double(millis) / 1000
    }
    
    static func milliseconds(from seconds: Double) -> Double {
        return Double(seconds * 1000)
    }
    
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

// MARK: - MockAnalytics
class MockAnalytics: Analytics {
    var isFlushed: Bool = false
    
    init() {
        let config = Configuration(writeKey: "_sample_write_key_", dataPlaneUrl: "https://www.datap_lane.com")
        super.init(configuration: config)
    }
    
    override func flush() {
        self.isFlushed = true
    }
}

// MARK: - Given_When_Then

func given(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("Given \(description)") }
    closure()
}

func when(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("When \(description)") }
    closure()
}

func then(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("Then \(description)") }
    closure()
}

func given(_ description: String = "", closure: () async throws -> Void) async rethrows {
    if !description.isEmpty { print("Given \(description)") }
    try await closure()
}

func when(_ description: String = "", closure: () async throws -> Void) async rethrows {
    if !description.isEmpty { print("When \(description)") }
    try await closure()
}

func then(_ description: String = "", closure: () async throws -> Void) async rethrows {
    if !description.isEmpty { print("Then \(description)") }
    try await closure()
}

// MARK: - Run After

func runAfter(_ seconds: Double, block: @escaping () async -> Void) async {
    // Suspend the current task for the specified duration
    let nanoseconds = UInt64(seconds * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
    
    // Execute the block after the delay
    await block()
}

// MARK: - Run After

func runAfter(_ seconds: Double, block: @escaping () async -> Void) async {
    // Suspend the current task for the specified duration
    let nanoseconds = UInt64(seconds * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
    
    // Execute the block after the delay
    await block()
}

// MARK: - String(Extension)
extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - MockNetworkMonitor
class MockNetworkMonitor: NetworkMonitorProtocol {
    var status: NWPath.Status
    var interfaces: [NWInterface.InterfaceType]
    
    init(status: NWPath.Status, interfaces: [NWInterface.InterfaceType]) {
        self.status = status
        self.interfaces = interfaces
    }
    
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        return interfaces.contains(type)
    }
    
    func start(queue: DispatchQueue) {
        // Simulate path update
    }
    
    func cancel() {
        // Simulate cancel behavior
    }
}

// MARK: - MockStateAction
struct MockStateAction<T>: StateAction {
    let mockReduce: (T) -> T
    
    func reduce(currentState: T) -> T {
        return mockReduce(currentState)
    }
}

// MARK: - MockKeyValueStorage
class MockKeyValueStorage: KeyValueStorage {
    
    private var userDefaults: UserDefaults?
    
    init() {
        self.userDefaults = UserDefaults(suiteName: "MockKeyValueStorage")
    }
    
    deinit {
        for key in self.userDefaults?.dictionaryRepresentation().keys ?? [:].keys {
            self.remove(key: key)
        }
        self.userDefaults?.synchronize()
        self.userDefaults = nil
    }
    
    func write<T: Codable>(value: T, key: String) {
        if self.isPrimitiveType(value) {
            self.userDefaults?.set(value, forKey: key)
        } else {
            guard let encodedData = try? JSONEncoder().encode(value) else { return }
            self.userDefaults?.set(encodedData, forKey: key)
        }
        self.userDefaults?.synchronize()
    }
    
    func read<T: Codable>(key: String) -> T? {
        var result: T?
        let rawValue = self.userDefaults?.object(forKey: key)
        if let rawData = rawValue as? Data {
            guard let decodedValue = try? JSONDecoder().decode(T.self, from: rawData) else { return nil }
            result = decodedValue
        } else {
            result = rawValue as? T
        }
        return result
    }
    
    func remove(key: String) {
        self.userDefaults?.removeObject(forKey: key)
        self.userDefaults?.synchronize()
    }
    
    private func isPrimitiveType<T: Codable>(_ value: T?) -> Bool {
        guard let value = value else { return true } // Since nil is also a primitive, & can be set to UserDefaults..
        
        return switch value {
        case is Int, is Double, is Float, is NSNumber, is Bool, is String, is Character,
            is [Int], is [Double], is [Float], is [NSNumber], is [Bool], is [String], is [Character]:
            true
        default:
            false
        }
    }
}

// MARK: - Mock Plugin
class MockPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    func intercept(event: Event) -> Event? {
        if var trackEvent = event as? TrackEvent {
            trackEvent.event = "New Event Name"
            return trackEvent
        }
        return event
    }
}
