//
//  DiskStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/09/24.
//

import Foundation

final class DiskStore {
    
    let writeKey: String
    let userDefaults: UserDefaults?
    let fileStorageURL: URL = FileManager.eventStorageURL
    
    private let FileOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.userDefaults = UserDefaults.rudder(self.writeKey)
    }
    
    func store(message: String) {
        let currentFilePath = self.currentFileURL.path()
        var newFile = false
        
        if !FileManager.default.fileExists(atPath: currentFilePath) {
            guard let filePath = FileManager.createFile(at: currentFilePath), self.writeTo(file: self.currentFileURL, content: Constants.batchPrefix) else { return }
            newFile = true
        }
        
        if let fileSize = FileManager.sizeOf(file: currentFilePath), fileSize > Constants.maxBatchSize {
            finish()
            self.store(message: message)
        }
        
        let content = newFile ? message : "," + message
        self.writeTo(file: self.currentFileURL, content: content)
    }
    
    func finish() {
        let currentFilePath = self.currentFileURL.path()
        guard FileManager.default.fileExists(atPath: currentFilePath) else { return }
        
        let content = Constants.batchSentAtSuffix + String.currentTimeStamp + Constants.batchSuffix
        self.writeTo(file: self.currentFileURL, content: content)
        FileManager.removePathExtension(from: currentFilePath)
        self.incrementFileIndex()
    }
    
    func readFiles() -> [String] {
        return FileManager.contentsOf(directory: self.currentFileURL.path()).filter { $0.lastPathComponent.contains(self.writeKey) && $0.pathExtension.isEmpty }.compactMap { $0.path() }
    }
    
    func remove(filePath: String) -> Bool {
        return FileManager.delete(file: filePath)
    }
    
    func rollover() {
        FileOperationQueue.addOperation {
            self.finish()
        }
    }
    
}

extension DiskStore {
    var fileIndexKey: String {
        return Constants.fileIndex + self.writeKey
    }
    
    var currentFileIndex: Int {
        return (self.userDefaults?.object(forKey: self.fileIndexKey) as? Int) ?? 0
    }
    
    var currentFileURL: URL {
        return self.fileStorageURL.appending(path: self.writeKey + "-\(self.currentFileIndex)").appendingPathExtension(Constants.fileType)
    }
    
    func incrementFileIndex() {
        self.userDefaults?.set(self.currentFileIndex + 1, forKey: self.fileIndexKey)
    }
    
    @discardableResult
    func writeTo(file: URL, content: String) -> Bool {
        do {
            try content.write(to: file, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
}

extension DiskStore: DataStore {
    
    func retain<T: Codable>(value: T?, key: String) {
        FileOperationQueue.addOperation {
            self.store(message: value as? String ?? "")
        }
    }
    
    func retrieve<T: Codable>(key: String) -> T? {
        return nil
    }
}
