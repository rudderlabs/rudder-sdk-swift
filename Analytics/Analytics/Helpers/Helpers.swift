//
//  Helpers.swift
//  Analytics
//
//  Created by Satheesh Kannan on 26/08/24.
//

import Foundation

// MARK: - Typealiases(Public)
public typealias RudderOptions = [String: Any]
public typealias RudderProperties = [String: Any]

// MARK: - Typealiases(Internal)
typealias PluginClosure = (Plugin) -> Void

// MARK: - Constants
public struct Constants {
    public static let logTag = "Rudder-Analytics"
    public static let defaultLogLevel: LogLevel = .none
    public static let defaultStorageMode: StorageMode = .disk
    public static let defaultControlPlaneUrl = "https://api.rudderlabs.com"
    public static let defaultGZipStatus = true
    
    //Internals
    static let fileIndex = "rudderstack.message.file.index."
    static let memoryIndex = "rudderstack.message.memory.index."
    static let maxPayloadSize: Int64 = 32 * 1024 //32kb
    static let maxBatchSize: Int64 = 500 * 1024 //500 kb
    static let fileType = "tmp"
    static let batchPrefix = "{\"batch\":["
    static let batchSentAtSuffix = "],\"sentAt\":\""
    static let batchSuffix = "\"}"
    static let configQueryParams = ["p": "ios", "v": "1.0.0"]
    static let uploadSignal = "#!upload!#"
    
    private init() {}
}

// MARK: - Extension: String
extension String {
    static var randomUUIDString: String {
        return UUID().uuidString
    }
    
    static var currentTimeStamp: String {
        return String.timeStampFromDate(Date()).replacingOccurrences(of: "+00:00", with: "Z")
    }
    
    static func timeStampFromDate(_ date: Date) -> String {
        let formattedDate = DateFormatter.timeStampFormat.string(from: date)
        return formattedDate.replacingOccurrences(of: "+00:00", with: "Z")
    }
    
    var utf8Data: Data? {
        return self.data(using: .utf8)
    }
    
    var base64Encoded: String? {
        return self.utf8Data?.base64EncodedString()
    }
    
    var trimmedUrlString: String {
        return self.hasSuffix("/") ? String(self.dropLast()) : self
    }
}

// MARK: - Extension: DateFormatter
extension DateFormatter {
    static var timeStampFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }
}

// MARK: - UserDefaults
extension UserDefaults {
    static func rudder(_ writeKey: String) -> UserDefaults? {
        let suiteName = (Bundle.main.bundleIdentifier ?? "com.rudder.poc") + ".analytics." + writeKey
        return UserDefaults(suiteName: suiteName)
    }
}

// MARK: - FileManager
extension FileManager {
    static var eventStorageURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let storageURL = directory[0].appending(path: "rudder/analytics/events", directoryHint: .isDirectory)
        
        try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
        return storageURL
    }
    
    static func createFile(at filePath: String) -> String? {
        guard !FileManager.default.fileExists(atPath: filePath) else { return filePath }
        guard FileManager.default.createFile(atPath: filePath, contents: nil) else { return nil }
        return filePath
    }
    
    static func sizeOf(file filePath: String) -> Int64? {
        guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath), let fileSize = fileAttributes[.size] as? Int64 else { return nil }
        return fileSize
    }
    
    @discardableResult
    static func removePathExtension(from filePath: String) -> Bool {
        let fileUrl = URL(fileURLWithPath: filePath)
        do {
            try FileManager.default.moveItem(atPath: fileUrl.path(), toPath: fileUrl.deletingPathExtension().path())
            return true
        } catch {
            return false
        }
    }
    
    static func contentsOf(directory: String) -> [URL] {
        guard let content = try? FileManager.default.contentsOfDirectory(atPath: directory) else { return [] }
        return content.compactMap { URL(fileURLWithPath: $0) }
    }
    
    static func contentsOf(file filePath: String) -> String? {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return nil }
        return content
    }
    
    @discardableResult
    static func delete(file filePath: String) -> Bool {
        let fileUrl = URL(fileURLWithPath: filePath)
        do {
            try FileManager.default.removeItem(at: fileUrl)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - KeyedDecodingContainer
extension KeyedDecodingContainer {
    func decodeDictionary(forKey key: K) throws -> [String: Any] {
        let dictionary = try self.decode([String: String].self, forKey: key)
        return dictionary // or transform as needed
    }
}

// MARK: - KeyedEncodingContainer
extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: K) throws {
        let dictionary = value as? [String: String] ?? [:] // or transform as needed
        try self.encode(dictionary, forKey: key)
    }
}

// MARK: - Encodable
extension Encodable {
    var toJSONString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Optional: for pretty-printed JSON
        do {
            let jsonData = try encoder.encode(self)
            return jsonData.toJSONString
        } catch {
            return nil
        }
    }
}

// MARK: - Data
extension Data {
    var toJSONString: String? {
        return String(data: self, encoding: .utf8)
    }
}

// MARK: - URL
extension URL {
    func appendQueryParameters(_ parameters: [String: String]) -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        return urlComponents.url ?? self
    }
}
