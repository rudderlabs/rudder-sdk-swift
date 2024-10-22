//
//  MemoryStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/09/24.
//

import Foundation

// MARK: - MemoryStore
/**
 A class designed to store and retrieve message events using memory storage.
 */
class MemoryStore {
    let writeKey: String
    @Synchronized var dataItems: [MessageDataItem] = []
    private let keyValueStore: KeyValueStore
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    private func store(message: String) {
        var dataItem = self.currentDataItem ?? MessageDataItem(batch: Constants.batchPrefix)
        let newEntry = dataItem.batch == Constants.batchPrefix
        
        if let existingData = dataItem.batch.utf8Data, existingData.count > Constants.maxBatchSize {
            self.finish {
                self.store(message: message)
            }
            return
        }
        
        let content = newEntry ? message : ("," + message)
        dataItem.batch += content
        
        self.appendDataItem(dataItem)
    }
    
    private func finish(_ block: VoidClosure? = nil) {
        guard var currentDataItem = self.currentDataItem else { block?(); return }
        currentDataItem.batch += Constants.batchSentAtSuffix + String.currentTimeStamp + Constants.batchSuffix
        currentDataItem.isClosed = true
        self.appendDataItem(currentDataItem)
        
        self.keyValueStore.delete(reference: self.currentDataItemKey)
        block?()
    }
    
    private func appendDataItem(_ item: MessageDataItem) {
        if let firstIndex = self.dataItems.firstIndex(where: { $0.id == item.id }) {
            self.dataItems[firstIndex] = item
        } else {
            self.dataItems.append(item)
        }
        
        self.keyValueStore.save(value: item.id, reference: self.currentDataItemKey)
    }
    
    private func collectDataItems() -> [MessageDataItem] {
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
        print("Item removed: \(id)")
        return true
    }
}

/**
 Private variables and functions to manage incoming message events.
 */

extension MemoryStore {
    private var currentDataItemKey: String {
        return Constants.memoryIndex + self.writeKey
    }
    
    private var currentDataItemId: String? {
        guard let currentItemId: String = self.keyValueStore.read(reference: self.currentDataItemKey) else { return nil }
        return currentItemId
    }
    
    private var currentDataItem: MessageDataItem? {
        guard let currentItemId = self.currentDataItemId else { return nil }
        return self.dataItems.filter { $0.id == currentItemId }.first
    }
}

// MARK: - DataStore
/**
 Implementation of the `DataStore` protocol.
 */
extension MemoryStore: DataStore {
    func retain(value: String) {
        SynchronizedQueue.perform {
            self.store(message: value)
        }
    }
    
    func retrieve() -> [Any] {
        return self.collectDataItems()
    }
    
    func remove(reference: String) -> Bool {
        return self.removeItem(using: reference)
    }
    
    func rollover(_ block: VoidClosure?) {
        SynchronizedQueue.perform {
            self.finish(block)
        }
    }
}
