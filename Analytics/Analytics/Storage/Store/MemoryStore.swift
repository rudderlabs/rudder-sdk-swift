//
//  MemoryStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/09/24.
//

import Foundation

class MemoryStore {
    
    let writeKey: String
    let userDefaults: UserDefaults?
    var dataItems: [EventDataItem] = []
    
    private let memoryOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        return queue
    }()
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.userDefaults = UserDefaults.rudder(writeKey)
    }
    
    private func store(message: String) {
        var dataItem = self.currentDataItem ?? EventDataItem(batch: Constants.batchPrefix)
        let newEntry = dataItem.batch == Constants.batchPrefix
        
        if let existingData = dataItem.batch.utf8Data, existingData.count > Constants.maxBatchSize {
            finish()
            self.store(message: message)
            return
        }
        
        let content = newEntry ? message : ("," + message)
        dataItem.batch += content
        
        self.appendDataItem(dataItem)
    }
    
    private func finish() {
        guard var currentDataItem = self.currentDataItem else { return }
        currentDataItem.batch += Constants.batchSentAtSuffix + String.currentTimeStamp + Constants.batchSuffix
        currentDataItem.isClosed = true
        self.appendDataItem(currentDataItem)

        self.userDefaults?.removeObject(forKey: self.currentDataItemKey)
        self.userDefaults?.synchronize()
    }
    
    private func appendDataItem(_ item: EventDataItem) {
        if let firstIndex = self.dataItems.firstIndex(where: { $0.id == item.id }) {
            self.dataItems[firstIndex] = item
        } else {
            self.dataItems.append(item)
        }
        self.userDefaults?.set(item.id, forKey: self.currentDataItemKey)
        self.userDefaults?.synchronize()
    }
    
    private func collectItems() -> [EventDataItem] {
        var filtered = self.dataItems.filter { $0.batch.hasSuffix(Constants.batchSuffix) && $0.isClosed }
        
        if let currentDataItem = self.currentDataItem {
            filtered = filtered.filter { $0.id != currentDataItem.id }
        }
        
        return filtered
    }
    
    @discardableResult
    private func removeItem(using id: String) -> Bool {
        guard let firstIndex = self.dataItems.firstIndex(where: { $0.id == id }) else { return false }
        self.dataItems.remove(at: firstIndex)
        return true
    }
}

extension MemoryStore {
    private var currentDataItemKey: String {
        return Constants.memoryIndex + self.writeKey
    }
    
    private var currentDataItemId: String? {
        guard let currentItemId = self.userDefaults?.object(forKey: self.currentDataItemKey) as? String else { return nil }
        return currentItemId
    }
    
    private var currentDataItem: EventDataItem? {
        guard let currentItemId = self.currentDataItemId else { return nil }
        return self.dataItems.filter { $0.id == currentItemId }.first
    }
}

extension MemoryStore: DataStore {
    func retain<T: Codable>(value: T?, reference: String) {
        self.memoryOperationQueue.addOperation {
            self.store(message: value as? String ?? "")
        }
    }
    
    func retrieve<T: Codable>(reference: String) -> T? {
        return self.collectItems() as? T
    }
    
    func remove(reference: String) {
        self.removeItem(using: reference)
    }
    
    func rollover() {
        self.memoryOperationQueue.addOperation {
            self.finish()
        }
    }
}
