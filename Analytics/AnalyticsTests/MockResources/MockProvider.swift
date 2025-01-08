//
//  MockProvider.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import XCTest
import Network
@testable import Analytics

// MARK: - MockProvider
final class MockProvider {
    private init() {}
    
    static var _mockWriteKey: String {
        return UUID().uuidString
    }
    static let keyValueStore: KeyValueStore = KeyValueStore(writeKey: _mockWriteKey)
    
    static var clientWithDiskStorage: AnalyticsClient {
        let storage = BasicStorage(writeKey: _mockWriteKey, storageMode: .disk)
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/512911fe-bf84-4742-9492-401c6889c7ba", storage: storage, flushPolicies: [])
        return AnalyticsClient(configuration: configuration)
    }
    
    static var clientWithMemoryStorage: AnalyticsClient {
        let storage = BasicStorage(writeKey: _mockWriteKey, storageMode: .memory)
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/512911fe-bf84-4742-9492-401c6889c7ba", storage: storage, flushPolicies: [])
        return AnalyticsClient(configuration: configuration)
    }
}

extension MockProvider {
    
    static let simpleTrackEvent: TrackEvent = {
        let event = TrackEvent(event: "Track_Event", properties: ["Property_1": "Value1"], options: RudderOptions().addCustomContext(["context_key": "context_value"], key: "custom_context"))
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
        let bundle = Bundle(for: MockProvider.self)
        guard let fileUrl = bundle.url(forResource: file, withExtension: "json"), let data = try? Data(contentsOf: fileUrl) else { return nil }
        return data.jsonString
    }
    
    static func resetDynamicValues(_ event: inout Message) {
        event.messageId = "<message-id>"
        event.anonymousId = "<anonymous-id>"
        event.originalTimeStamp = "<original-timestamp>"
    }
}

// MARK: - MockAnalyticsClient
class MockAnalyticsClient: AnalyticsClient {
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
extension XCTestCase {
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
}

extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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

class MockKeyValueStorage: KeyValueStorage {
    
    private var userDefaults: UserDefaults?
    
    init() {
        self.userDefaults = UserDefaults(suiteName: "MockKeyValueStorage")
    }
    
    deinit {
        for key in self.userDefaults?.dictionaryRepresentation().keys ?? [:].keys {
            self.userDefaults?.removeObject(forKey: key)
        }
        self.userDefaults?.synchronize()
        self.userDefaults = nil
    }
    
    func write<T>(value: T, key: String) where T : Decodable, T : Encodable {
        if self.isPrimitiveType(value) {
            self.userDefaults?.set(value, forKey: key)
        } else {
            guard let encodedData = try? JSONEncoder().encode(value) else { return }
            self.userDefaults?.set(encodedData, forKey: key)
        }
        self.userDefaults?.synchronize()
    }
    
    func read<T>(key: String) -> T? where T : Decodable, T : Encodable {
        var result: T? = nil
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
        guard let value = value else { return true } //Since nil is also a primitive, & can be set to UserDefaults..
        
        return switch value {
        case is Int, is Double, is Float, is NSNumber, is Bool, is String, is Character,
            is [Int], is [Double], is [Float], is [NSNumber], is [Bool], is [String], is [Character]:
            true
        default:
            false
        }
    }
}

