//
//  DiskStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/09/24.
//

import Foundation
// MARK: - DiskStore
/**
 An actor designed to store and retrieve incoming events using file system storage.
 */
final actor DiskStore {
    
    let writeKey: String
    var fileStorageURL: URL
    private let keyValueStore: KeyValueStore
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.fileStorageURL = FileManager.eventStorageURL.appendingPathComponent(self.writeKey)
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    private func store(event: String) {
        
        // Create directory if it doesn't exist
        FileManager.createDirectoryIfNeeded(at: self.fileStorageURL)
        
        var currentFilePath = self.currentFileURL.path
        var newFile = false
        if !FileManager.default.fileExists(atPath: currentFilePath) {
            guard let filePath = FileManager.createFile(at: currentFilePath), self.writeTo(file: self.currentFileURL, content: DataStoreConstants.fileBatchPrefix) else { return }
            currentFilePath = filePath
            newFile = true
        }
        
        if let fileSize = FileManager.sizeOf(file: currentFilePath), fileSize > DataStoreConstants.maxBatchSize {
            self.finish()
            LoggerAnalytics.debug(log: "Batch size exceeded. Closing the current batch.")
            self.store(event: event)
            return
        }
        
        let content = newFile ? event : ("," + event)
        self.writeTo(file: self.currentFileURL, content: content)
    }
    
    private func finish() {
        let currentFilePath = self.currentFileURL.path
        guard FileManager.default.fileExists(atPath: currentFilePath) else { return }
        
        let content = DataStoreConstants.fileBatchSentAtSuffix + String.currentTimeStamp + DataStoreConstants.fileBatchSuffix
        self.writeTo(file: self.currentFileURL, content: content)
        FileManager.removePathExtension(from: currentFilePath)
        self.incrementFileIndex()
    }
    
    private func collectFiles() -> [String] {
        let directory = self.currentFileURL.deletingLastPathComponent()
        return FileManager.contentsOf(directory: directory.path)
            .filter { $0.pathExtension.isEmpty }
            .map { directory.appendingPathComponent($0.lastPathComponent).path }
            .sorted {
                let lhsIndex = Int(URL(fileURLWithPath: $0).lastPathComponent) ?? 0
                let rhsIndex = Int(URL(fileURLWithPath: $1).lastPathComponent) ?? 0
                return lhsIndex < rhsIndex
            }
    }
    
    private func removeItems(using reference: String) {
        let folderPath = (reference as NSString).deletingLastPathComponent
        let result = FileManager.delete(item: folderPath)
        result ? LoggerAnalytics.debug(log: "Successfully removed folder: \(folderPath)") : LoggerAnalytics.debug(log: "Folder does not exist: \(folderPath)")
    }
}

/**
 Private variables and functions to manage incoming events.
 */
extension DiskStore {
    private var fileIndexKey: String {
        return DataStoreConstants.fileIndex + self.writeKey
    }
    
    private var currentFileIndex: Int {
        guard let index: Int = self.keyValueStore.read(reference: self.fileIndexKey) else { return 0 }
        return index
    }
    
    private var currentFileURL: URL {
        return self.fileStorageURL.appendingPathComponent( "\(self.currentFileIndex)").appendingPathExtension(DataStoreConstants.fileType)
    }
    
    private func incrementFileIndex() {
        self.keyValueStore.save(value: self.currentFileIndex + 1, reference: self.fileIndexKey)
    }
    
    @discardableResult
    private func writeTo(file: URL, content: String) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: file.path) {
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
    func retain(value: String) async {
        await withCheckedContinuation { continuation in
            self.store(event: value)
            continuation.resume()
        }
    }
    
    func retrieve() async -> [EventDataItem] {
        await withCheckedContinuation { continuation in
            var dataItems = [EventDataItem]()
            for file in self.collectFiles() {
                guard FileManager.default.fileExists(atPath: file) else { continue }
                
                var item = EventDataItem()
                item.reference = file
                item.isClosed = true
                
                dataItems.append(item)
            }
            continuation.resume(returning: dataItems)
        }
    }
    
    func remove(reference filePath: String) async -> Bool {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: FileManager.delete(item: filePath))
        }
    }
    
    func removeAll(reference: String) async {
        await withCheckedContinuation { continuation in
            self.removeItems(using: reference)
            continuation.resume()
        }
    }
    
    func rollover() async {
        await withCheckedContinuation { continuation in
            self.finish()
            continuation.resume()
        }
    }
}
