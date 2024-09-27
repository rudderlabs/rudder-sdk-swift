//
//  DiskStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/09/24.
//

import Foundation
// MARK: - DiskStore
/**
 A class designed to store and retrieve message events using file system storage.
 */
final class DiskStore {
    
    let writeKey: String
    let fileStorageURL: URL = FileManager.eventStorageURL
    private let keyValueStore: KeyValueStore
        
    init(writeKey: String) {
        self.writeKey = writeKey
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    private func store(message: String) {
        var currentFilePath = self.currentFileURL.path()
        var newFile = false
        if !FileManager.default.fileExists(atPath: currentFilePath) {
            guard let filePath = FileManager.createFile(at: currentFilePath), self.writeTo(file: self.currentFileURL, content: Constants.batchPrefix) else { return }
            currentFilePath = filePath
            newFile = true
        }
        
        if let fileSize = FileManager.sizeOf(file: currentFilePath), fileSize > Constants.maxBatchSize {
            finish()
            self.store(message: message)
            return
        }
        
        let content = newFile ? message : ("," + message)
        self.writeTo(file: self.currentFileURL, content: content)
    }
    
    private func finish() {
        let currentFilePath = self.currentFileURL.path()
        guard FileManager.default.fileExists(atPath: currentFilePath) else { return }
        
        let content = Constants.batchSentAtSuffix + String.currentTimeStamp + Constants.batchSuffix
        self.writeTo(file: self.currentFileURL, content: content)
        FileManager.removePathExtension(from: currentFilePath)
        self.incrementFileIndex()
    }
    
    private func collectFiles() -> [String] {
        let directory = self.currentFileURL.deletingLastPathComponent()
        return FileManager.contentsOf(directory: directory.path()).filter { $0.lastPathComponent.contains(self.writeKey) && $0.pathExtension.isEmpty }.compactMap { directory.path() + "/" + $0.path() }.sorted()
    }
}

/**
 Private variables and functions to manage incoming message events.
 */
extension DiskStore {
    private var fileIndexKey: String {
        return Constants.fileIndex + self.writeKey
    }
    
    private var currentFileIndex: Int {
        guard let index: Int = self.keyValueStore.read(reference: self.fileIndexKey) else { return 0 }
        return index
    }
    
    private var currentFileURL: URL {
        return self.fileStorageURL.appending(path: self.writeKey + "-\(self.currentFileIndex)").appendingPathExtension(Constants.fileType)
    }
    
    private func incrementFileIndex() {
        self.keyValueStore.save(value: self.currentFileIndex + 1, reference: self.fileIndexKey)
    }
    
    @discardableResult
    private func writeTo(file: URL, content: String) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: file.path()) {
                let fileHandler = try FileHandle(forWritingTo: file)
                try fileHandler.seekToEnd()
                
                guard let data = content.utf8Data else { return false }
                try fileHandler.write(contentsOf: data)
                try fileHandler.close()
                
            } else {
                try content.write(to: file, atomically: true, encoding: .utf8)
            }
            return true
        } catch {
            return false
        }
    }
}

// MARK: - DataStore
/**
 Implementation of the `DataStore` protocol.
 */
extension DiskStore: DataStore {
    func retain(value: String) {
        StorageQueue.perform {
            self.store(message: value)
        }
    }
    
    func retrieve() -> [Any] {
        return self.collectFiles().compactMap { URL(fileURLWithPath: $0) }
    }
    
    func remove(reference filePath: String) -> Bool {
        return FileManager.delete(file: filePath)
    }
    
    func rollover() {
        StorageQueue.perform {
            self.finish()
        }
    }
}
