//
//  Extensions.swift
//  Analytics
//
//  Created by Satheesh Kannan on 21/10/24.
//

import Foundation
import zlib

// MARK: - String
extension String {
    static let empty: String = ""
    
    static var randomUUIDString: String {
        return UUID().uuidString.lowercased()
    }
    
    static var currentTimeStamp: String {
        return Date().iso8601TimeStamp
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
    
    var toDictionary: [String: Any]? {
        guard let data = self.utf8Data else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

// MARK: - Date
extension Date {
    fileprivate static let isoTimeStampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    var iso8601TimeStamp: String {
        return Date.isoTimeStampFormatter.string(from: self)
    }
    
    static func date(from timeStamp: String) -> Date? {
        return Date.isoTimeStampFormatter.date(from: timeStamp)
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
        let storageURL: URL
        
        // Check if we're running in a test environment
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // Use temporary directory for tests to avoid polluting user files
            let tempDir = FileManager.default.temporaryDirectory
            storageURL = tempDir.appendingPathComponent("rudder-analytics-tests/events", isDirectory: true)
        } else {
            // Use Application Support directory for production (more appropriate than Documents)
            #if os(macOS)
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            #else
            // On iOS/tvOS/watchOS, use Documents directory (sandboxed to app)
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            #endif
            storageURL = directory[0].appendingPathComponent("rudder/analytics/events", isDirectory: true)
        }
        
        return storageURL
    }
    
    static func createDirectoryIfNeeded(at url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
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
            try FileManager.default.moveItem(atPath: fileUrl.path, toPath: fileUrl.deletingPathExtension().path)
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
    static func delete(item path: String) -> Bool {
        let fileUrl = URL(fileURLWithPath: path)
        do {
            try FileManager.default.removeItem(at: fileUrl)
            LoggerAnalytics.debug("Removed item at path: \(path)")
            return true
        } catch {
            LoggerAnalytics.error("Failed to remove item at path: \(path)", cause: error)
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
    var jsonString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        do {
            let jsonData = try encoder.encode(self)
            return jsonData.jsonString
        } catch {
            LoggerAnalytics.error("Encoding JSON Error", cause: error)
            return nil
        }
    }
    
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) as? [String: Any]
    }
}

// MARK: - URL
extension URL {
    func appendQueryParameters(_ parameters: [String: String]) -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        return urlComponents.url ?? self
    }
    
    var queryItems: [URLQueryItem] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return []
        }
        return items
    }
    
    var queryParameters: [String: String] {
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name] = value
            }
        }
        return params
    }
}

// MARK: - Dictionary
extension Dictionary where Key == String {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        return lhs.merging(rhs) { (_, new) in new }
    }
}

// MARK: - [String: Any]
extension Dictionary where Key == String, Value == Any {
    var jsonString: String? {
        return try? JSONSerialization.data(withJSONObject: self, options: []).jsonString
    }
    
    var objCSanitized: [String: Any] {
        self.mapValues { objCSanitizeValue($0) }
    }
}

// MARK: - [String: Any]
public extension Dictionary where Key == String, Value == Any {
    /** A computed property that converts `[String: Any]` to `[String: AnyCodable]` */
    var codableWrapped: [String: AnyCodable] {
        return self.mapValues { AnyCodable($0) }
    }
}

// MARK: - [String: AnyCodable]
public extension Dictionary where Key == String, Value == AnyCodable {
    /** A computed property that converts `[String: AnyCodable]` to `[String: Any]` */
    var rawDictionary: [String: Any] {
        self.mapValues { $0.value }
    }
}

// MARK: - [AnyCodable]
public extension Array where Element == AnyCodable {
    /** A computed property that converts `[AnyCodable]` to `[Any]` */
    var rawArray: [Any] {
        self.map { $0.value }
    }
}

// MARK: - [Any]
public extension Array where Element == Any {
    /** A computed property that converts `[Any]` to `[AnyCodable]` */
    var codableWrapped: [AnyCodable] {
        self.map { AnyCodable($0) }
    }
}

// MARK: - [Any]
extension Array where Element == Any {
    var objCSanitized: [Any] {
        self.map { objCSanitizeValue($0) }
    }
}

// MARK: - ObjC Sanitization Helper
/**
 Recursively sanitizes values to ensure compatibility with Objective-C.
 
 This function handles NSNumber type disambiguation (which is crucial for Objective-C interop),
 and recursively processes nested arrays and dictionaries.
 */
private func objCSanitizeValue(_ value: Any) -> Any {
    switch value {
    case let number as NSNumber:
        return sanitizeNSNumber(number)
    case let array as [Any]:
        return array.objCSanitized
    case let dict as [String: Any]:
        return dict.objCSanitized
    default:
        return value
    }
}

/**
 Sanitizes NSNumber objects by examining their underlying Objective-C type encoding.
 
 This is necessary because NSNumber can represent different primitive types (Bool, Int, Float, Double)
 but Objective-C needs explicit type information.
 */
private func sanitizeNSNumber(_ number: NSNumber) -> Any {
    let objCType = String(cString: number.objCType)
    
    switch objCType {
    case "c", "C": // Bool (char/unsigned char when used for BOOL)
        return number.boolValue
    case "s", "S", "i", "I", "l", "L", "q", "Q": // All integer types
        return number.intValue
    case "f": // Float (32-bit)
        // Convert through string to maintain precision consistency
        let stringValue = String(describing: number.floatValue)
        return Double(stringValue) ?? Double(number.floatValue)
    case "d": // Double (64-bit)
        return number.doubleValue
    default:
        // For unknown types, return the original NSNumber
        return number
    }
}

// MARK: - AnyCodable
extension AnyCodable {
    /**
     * Attempts to extract a boolean value from the wrapped value.
     *
     * This method is primarily used by the IntegrationOptionsPlugin to safely
     * extract boolean flags from integration settings while ignoring non-boolean values.
     *
     * - Returns: The boolean value if the wrapped value is a Bool, otherwise nil.
     *
     * # Usage
     * ```swift
     * let integrations: [String: AnyCodable] = ["Firebase": AnyCodable(true)]
     * let isEnabled = integrations["Firebase"]?.asBool() // Returns true
     * ```
     */
    func asBool() -> Bool? {
        return value as? Bool
    }
}

// MARK: - Data
extension Data {
    var jsonString: String? {
        return String(data: self, encoding: .utf8)
    }
    
    var prettyPrintedString: String? {
        guard let dict = try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any], let prettyData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted), let pretty = prettyData.jsonString else { return nil }
        return pretty
    }
}

// MARK: - Result<Data, Error>
extension Result where Success == Data, Failure == Error {
    var eventUploadResult: EventUploadResult {
        switch self {
        case .success(let data): .success(data)
        case .failure(let error):
            if let httpError = error as? HttpNetworkError {
                switch httpError {
                case .networkUnavailable: .failure(RetryableEventUploadError.networkUnavailable)
                case .requestFailed(let statusCode):
                    if let nonRetryable = NonRetryableEventUploadError(rawValue: statusCode) {
                        .failure(nonRetryable)
                    } else {
                        .failure(RetryableEventUploadError.retryable(statusCode: statusCode))
                    }
                case .invalidResponse, .unknown: .failure(RetryableEventUploadError.unknown)
                }
            } else {
                .failure(RetryableEventUploadError.unknown)
            }
        }
    }
    
    var sourceConfigResult: SourceConfigResult {
        switch self {
        case .success(let data): .success(data)
        case .failure(let error):
            if let httpError = error as? HttpNetworkError {
                switch httpError {
                case .networkUnavailable: .failure(SourceConfigError.networkUnavailable)
                case .requestFailed(let statusCode):
                    if statusCode == NonRetryableEventUploadError.error400.rawValue {
                        .failure(SourceConfigError.invalidWriteKey)
                    } else {
                        .failure(SourceConfigError.requestFailed(statusCode))
                    }
                case .invalidResponse, .unknown: .failure(SourceConfigError.unknown)
                }
            } else {
                .failure(SourceConfigError.unknown)
            }
        }
    }
}

// MARK: - TypeIdentifiable
/**
 A protocol to provide class name information for conforming types.
 */
protocol TypeIdentifiable {
    static var className: String { get }
    var className: String { get }
}

extension TypeIdentifiable {
    static var className: String {
        String(describing: Self.self)
    }

    var className: String {
        String(describing: Self.self)
    }
}

// MARK: - Gzip

enum Gzip {
    static let maxWindowBits = MAX_WBITS
}

struct CompressionLevel: RawRepresentable, Sendable {
    let rawValue: Int32
    static let noCompression = Self(rawValue: Z_NO_COMPRESSION)
    static let bestSpeed = Self(rawValue: Z_BEST_SPEED)
    static let bestCompression = Self(rawValue: Z_BEST_COMPRESSION)
    static let defaultCompression = Self(rawValue: Z_DEFAULT_COMPRESSION)
}

struct GzipError: Swift.Error, Sendable {
    let message: String
    init(code: Int32, msg: UnsafePointer<CChar>?) {
        self.message = msg.flatMap { String(validatingUTF8: $0) } ?? "Unknown gzip error"
    }
}

extension Data {
    // swiftlint:disable force_unwrapping
    // swiftlint:disable no_magic_numbers
    var isGzipped: Bool {
        return self.starts(with: [0x1f, 0x8b])
    }
    
    func gzipped(level: CompressionLevel = .defaultCompression, wBits: Int32 = Gzip.maxWindowBits + 16) throws -> Data {
        guard !self.isEmpty else { return Data() }
        
        var stream = z_stream()
        var status = deflateInit2_(&stream, level.rawValue, Z_DEFLATED, wBits, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else { throw GzipError(code: status, msg: stream.msg) }
        
        // Create a mutable data buffer with an initial capacity
        let data = Data(capacity: 16 * 1024)
        var outputData = data // Create a separate output variable
        
        repeat {
            // Ensure that the outputData can accommodate additional bytes
            if Int(stream.total_out) >= outputData.count {
                outputData.count += 16 * 1024
            }
            
            // Use a local buffer to avoid overlapping access
            let inputCount = self.count
            let inputPointer = self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) -> UnsafeRawPointer in
                return inputPointer.baseAddress!
            }
            
            let outputPointer = outputData.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) -> UnsafeMutableRawPointer in
                return outputPointer.baseAddress!.advanced(by: Int(stream.total_out))
            }
            
            // Set up stream properties
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.assumingMemoryBound(to: Bytef.self))
            stream.avail_in = uInt(inputCount) // Available input size
            stream.next_out = UnsafeMutablePointer<Bytef>(mutating: outputPointer.assumingMemoryBound(to: Bytef.self))
            stream.avail_out = uInt(outputData.count) - uInt(stream.total_out) // Available output size
            
            status = deflate(&stream, Z_FINISH)
            
        } while stream.avail_out == 0 && status != Z_STREAM_END
        
        guard deflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }
        
        outputData.count = Int(stream.total_out)
        return outputData // Return the newly compressed data
    }
    
    func gunzipped(wBits: Int32 = Gzip.maxWindowBits + 32) throws -> Data {
        guard !self.isEmpty else { return Data() }
        
        var stream = z_stream()
        var status = inflateInit2_(&stream, wBits, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else { throw GzipError(code: status, msg: stream.msg) }
        
        // Create a buffer for the output data with double the size of the input data.
        var data = Data(capacity: self.count * 2)
        
        repeat {
            // Resize the data buffer if necessary
            if Int(stream.total_out) >= data.count {
                data.count += self.count / 2
            }
            
            // Use local variables to avoid overlapping accesses
            let inputCount = self.count
            let outputCount = data.count
            
            // Access input data
            self.withUnsafeBytes { input in
                // Access output data
                data.withUnsafeMutableBytes { output in
                    // Set up the zlib stream
                    stream.next_in = UnsafeMutablePointer<Bytef>(mutating: input.bindMemory(to: Bytef.self).baseAddress!)
                    stream.avail_in = uInt(inputCount)
                    stream.next_out = output.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                    
                    // Inflate the data
                    status = inflate(&stream, Z_SYNC_FLUSH)
                }
            }
            
        } while stream.avail_out == 0 && status != Z_STREAM_END
        
        // Clean up
        guard inflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }
        
        // Resize the data to the actual decompressed size
        data.count = Int(stream.total_out)
        return data
    }
    // swiftlint:enable force_unwrapping
    // swiftlint:enable no_magic_numbers
}
