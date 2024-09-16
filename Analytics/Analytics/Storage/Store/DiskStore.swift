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
        queue.qualityOfService = .background
        return queue
    }()
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.userDefaults = UserDefaults.rudder(self.writeKey)
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
    
    func readFiles() -> [String] {
        let directory = self.currentFileURL.deletingLastPathComponent()
        return FileManager.contentsOf(directory: directory.path()).filter { $0.lastPathComponent.contains(self.writeKey) && $0.pathExtension.isEmpty }.compactMap { directory.path() + "/" + $0.path() }.sorted()
    }
    
    func rollover() {// Finish the currewnt file, & move to new one...
        FileOperationQueue.addOperation {
            self.finish()
        }
    }
}

extension DiskStore {
    private var fileIndexKey: String {
        return Constants.fileIndex + self.writeKey
    }
    
    private var currentFileIndex: Int {
        return (self.userDefaults?.object(forKey: self.fileIndexKey) as? Int) ?? 0
    }
    
    private var currentFileURL: URL {
        return self.fileStorageURL.appending(path: self.writeKey + "-\(self.currentFileIndex)").appendingPathExtension(Constants.fileType)
    }
    
    private func incrementFileIndex() {
        self.userDefaults?.set(self.currentFileIndex + 1, forKey: self.fileIndexKey)
        self.userDefaults?.synchronize()
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
    
    private func readFrom(file filePath: String) -> String? {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return nil }
        return content
    }
}

extension DiskStore: DataStore {
    func retain<T: Codable>(value: T?, reference: String){
        FileOperationQueue.addOperation {
            self.store(message: value as? String ?? "")
        }
    }
    
    func retrieve<T: Codable>(reference filePath: String) -> T? {
        return self.readFrom(file: filePath) as? T
    }
    
    func remove(reference filePath: String) {
        FileManager.delete(file: filePath)
    }
}
