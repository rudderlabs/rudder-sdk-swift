//
//  MockProvider.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import XCTest
@testable import Analytics

// MARK: - MockProvider
final class MockProvider {
    private init() {}
    
    static let _mockWriteKey = "MoCk_WrItEkEy"
    
    static let simpleTrackEvent: TrackEvent = {
        let event = TrackEvent(event: "Track_Event", properties: ["Property_1": "Value1"], options: RudderOptions().addCustomContext(["context_key": "context_value"], key: "custom_context"))
        return event
    }()
}

// MARK: - KeyValueStore
extension MockProvider {
    static let keyValueStore: KeyValueStore = KeyValueStore(writeKey: _mockWriteKey)
}

// MARK: - DiskStore
extension MockProvider {
    
    static let clientWithDiskStorage: AnalyticsClient = {
        let storage = BasicStorage(writeKey: _mockWriteKey, storageMode: .disk)
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/512911fe-bf84-4742-9492-401c6889c7ba", storage: storage)
        
        return AnalyticsClient(configuration: configuration)
    }()
    
    static var fileIndexKey: String {
        return Constants.fileIndex + MockProvider._mockWriteKey
    }
    
    static var currentFileIndex: Int {
        guard let index: Int = self.keyValueStore.read(reference: self.fileIndexKey) else { return 0 }
        return index
    }
    
    static var currentFileURL: URL {
        return FileManager.eventStorageURL.appending(path: MockProvider._mockWriteKey + "-\(self.currentFileIndex)").appendingPathExtension(Constants.fileType)
    }
    
    static func currentFolderContents() { //This function will be removed in near future....
        let folderPath = self.currentFileURL.deletingLastPathComponent().path()
        print("//--------------------------------//")
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: folderPath)
            print("Folder: \(folderPath)")
            print("Folder contents: \(contents)")
        } catch {
            print("Error accessing folder: \(error)")
        }
        print("//--------------------------------//")
    }
    
    static func resetDiskStorage() {
        FileManager.delete(file: Self.currentFileURL.path())
        self.keyValueStore.delete(reference: self.fileIndexKey)
    }
}

extension MockProvider {
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

// MARK: - MemoryStore
extension MockProvider {
    
    static let clientWithMemoryStorage: AnalyticsClient = {
        let storage = BasicStorage(writeKey: _mockWriteKey, storageMode: .memory)
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://run.mocky.io/v3/512911fe-bf84-4742-9492-401c6889c7ba", storage: storage)
        
        return AnalyticsClient(configuration: configuration)
    }()
    
    static var currentDataItemKey: String {
        return Constants.memoryIndex + _mockWriteKey
    }
    
    static var currentDataItemId: String? {
        guard let currentItemId: String = self.keyValueStore.read(reference: self.currentDataItemKey) else { return nil }
        return currentItemId
    }
    
    static func resetMemoryStorage() {
        self.keyValueStore.delete(reference: self.currentDataItemKey)
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
        let bundle = Bundle(for: MockProvider.self)
        guard let fileUrl = bundle.url(forResource: file, withExtension: "json"), let data = try? Data(contentsOf: fileUrl) else { return nil }
        return data.jsonString
    }
    
    static func resetDynamicValues(_ event: inout Message) {
        event.messageId = "<message-id>"
        event.anonymousId = "<anonymous-id>"
        event.originalTimeStamp = "<original-timestamp>"
        
        if let traits = event.traits?.dictionary {
            var processedTraits = [String: Any]()
            traits.forEach { processedTraits[$0.key] = $0.value.value }
            processedTraits["anonymousId"] = "<anonymous-id>"
            event.traits = CodableCollection(dictionary: processedTraits)
        }
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
