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
    static var randomUUIDString: String {
        return UUID().uuidString
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
}

// MARK: - DateFormatter
extension DateFormatter {
    static var timeStampFormat: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

// MARK: - Date
extension Date {
    var iso8601TimeStamp: String {
        return DateFormatter.timeStampFormat.string(from: self)
    }
    
    static func date(from timeStamp: String) -> Date? {
        return DateFormatter.timeStampFormat.date(from: timeStamp)
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
        let storageURL = directory[0].appendingPathComponent("rudder/analytics/events", isDirectory: true)
        
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
    static func delete(file filePath: String) -> Bool {
        let fileUrl = URL(fileURLWithPath: filePath)
        do {
            try FileManager.default.removeItem(at: fileUrl)
            print("File deleted: \(filePath)")
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
    var jsonString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        do {
            let jsonData = try encoder.encode(self)
            return jsonData.jsonString
        } catch {
            print("Error encoding JSON: \(error)")
            return nil
        }
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

// MARK: - [String: AnyCodable]
extension [String: AnyCodable] {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        return lhs.merging(rhs) { (_, new) in new }
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

// MARK: - Gzip

enum Gzip {
    public static let maxWindowBits = MAX_WBITS
}

struct CompressionLevel: RawRepresentable, Sendable {
    public let rawValue: Int32
    public static let noCompression = Self(rawValue: Z_NO_COMPRESSION)
    public static let bestSpeed = Self(rawValue: Z_BEST_SPEED)
    public static let bestCompression = Self(rawValue: Z_BEST_COMPRESSION)
    public static let defaultCompression = Self(rawValue: Z_DEFAULT_COMPRESSION)
    
    public init(rawValue: Int32) { self.rawValue = rawValue }
}

struct GzipError: Swift.Error, Sendable {
    public let message: String
    public init(code: Int32, msg: UnsafePointer<CChar>?) {
        self.message = msg.flatMap { String(validatingUTF8: $0) } ?? "Unknown gzip error"
    }
}

extension Data {
    
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
}
