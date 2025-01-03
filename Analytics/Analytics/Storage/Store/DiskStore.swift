//
//  DiskStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/09/24.
//

import Foundation
// MARK: - DiskStore
/**
 An actor designed to store and retrieve message events using file system storage.
 */
final actor DiskStore {
    
    let writeKey: String
    let fileStorageURL: URL = FileManager.eventStorageURL
    private let keyValueStore: KeyValueStore
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    private func store(message: String) {
        var currentFilePath = self.currentFileURL.path
        var newFile = false
        if !FileManager.default.fileExists(atPath: currentFilePath) {
            guard let filePath = FileManager.createFile(at: currentFilePath), self.writeTo(file: self.currentFileURL, content: Constants.batchPrefix) else { return }
            currentFilePath = filePath
            newFile = true
        }
        
        if let fileSize = FileManager.sizeOf(file: currentFilePath), fileSize > Constants.maxBatchSize {
            self.finish()
            print("Batch size exceeded. Closing the current batch.")
            self.store(message: message)
            return
        }
        
        let content = newFile ? message : ("," + message)
        self.writeTo(file: self.currentFileURL, content: content)
    }
    
    private func finish() {
        let currentFilePath = self.currentFileURL.path
        guard FileManager.default.fileExists(atPath: currentFilePath) else { return }
        
        let content = Constants.batchSentAtSuffix + String.currentTimeStamp + Constants.batchSuffix
        self.writeTo(file: self.currentFileURL, content: content)
        FileManager.removePathExtension(from: currentFilePath)
        self.incrementFileIndex()
    }
    
    private func collectFiles() -> [String] {
        let directory = self.currentFileURL.deletingLastPathComponent()
        return FileManager.contentsOf(directory: directory.path)
            .filter { $0.lastPathComponent.contains(self.writeKey) && $0.pathExtension.isEmpty }
            .map { directory.appendingPathComponent($0.lastPathComponent).path }
            .sorted {
                let idx1 = Int($0.components(separatedBy: Constants.fileNameSeparator).last ?? "") ?? 0
                let idx2 = Int($1.components(separatedBy: Constants.fileNameSeparator).last ?? "") ?? 0
                return idx1 < idx2
            }
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
        return self.fileStorageURL.appendingPathComponent(self.writeKey + "\(Constants.fileNameSeparator)\(self.currentFileIndex)").appendingPathExtension(Constants.fileType)
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
            self.store(message: value)
            continuation.resume()
        }
    }
    
    func retrieve() async -> [MessageDataItem] {
        await withCheckedContinuation { continuation in
            var dataItems = [MessageDataItem]()
            for file in self.collectFiles() {
                guard let batch = FileManager.contentsOf(file: file) else { continue }
                
                var item = MessageDataItem(batch: batch)
                item.reference = file
                item.isClosed = true
                
                dataItems.append(item)
            }
            continuation.resume(returning: dataItems)
        }
    }
    
    func remove(reference filePath: String) async -> Bool {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: FileManager.delete(file: filePath))
        }
    }
    
    func rollover() async{
        await withCheckedContinuation { continuation in
            self.finish()
            continuation.resume()
        }
    }
}
