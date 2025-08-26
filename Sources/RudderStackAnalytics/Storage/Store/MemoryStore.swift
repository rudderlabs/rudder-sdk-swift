//
//  MemoryStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/09/24.
//

import Foundation

// MARK: - MemoryStore
/**
 An actor designed to store and retrieve events using memory storage.
 */
final actor MemoryStore {
    
    let writeKey: String
    var dataItems: [EventDataItem] = []
    private let keyValueStore: KeyValueStore
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    private func store(event: String) {
        var dataItem = self.currentDataItem ?? EventDataItem(batch: DataStoreConstants.fileBatchPrefix)
        dataItem.reference = self.appendWriteKey(with: dataItem.reference)
        
        let newEntry = dataItem.batch == DataStoreConstants.fileBatchPrefix
        
        if let existingData = dataItem.batch.utf8Data, existingData.count > DataStoreConstants.maxBatchSize {
            self.finish()
            LoggerAnalytics.info(log: "Batch size exceeded. Closing the current batch..")
            self.store(event: event)
            return
        }
        
        let content = newEntry ? event : ("," + event)
        dataItem.batch += content
        
        self.appendDataItem(dataItem)
    }
    
    private func finish() {
        guard var currentDataItem = self.currentDataItem else { return }
        currentDataItem.batch += DataStoreConstants.fileBatchSentAtSuffix + String.currentTimeStamp + DataStoreConstants.fileBatchSuffix
        currentDataItem.isClosed = true
        self.appendDataItem(currentDataItem)
        
        self.keyValueStore.delete(reference: self.currentDataItemKey)
    }
    
    private func appendDataItem(_ item: EventDataItem) {
        if let firstIndex = self.dataItems.firstIndex(where: { $0.reference == item.reference }) {
            self.dataItems[firstIndex] = item
        } else {
            self.dataItems.append(item)
        }
        
        self.keyValueStore.save(value: item.reference, reference: self.currentDataItemKey)
    }
    
    private func collectDataItems() -> [EventDataItem] {
        var filtered = self.dataItems.filter { $0.batch.hasSuffix(DataStoreConstants.fileBatchSuffix) && $0.isClosed }
        
        if let currentDataItem = self.currentDataItem {
            filtered = filtered.filter { $0.reference != currentDataItem.reference }
        }
        
        return filtered
    }
    
    @discardableResult
    private func removeItem(using id: String) -> Bool {
        guard let firstIndex = self.dataItems.firstIndex(where: { $0.reference == id }) else { return false }
        self.dataItems.remove(at: firstIndex)
        LoggerAnalytics.debug(log: "Item removed: \(id)")
        return true
    }
    
    private func removeItems(using reference: String) {
        guard let writeKey = self.recoverWriteKey(from: reference) else { return }
        self.dataItems.removeAll { $0.reference.hasPrefix(writeKey) }
        LoggerAnalytics.debug(log: "Items removed related to reference: \(reference)")
    }
}

/**
 Helper functions for managing batch references.
 */
extension MemoryStore {
    private func appendWriteKey(with reference: String) -> String {
        guard !reference.hasPrefix(self.writeKey) else { return reference }
        return self.writeKey + DataStoreConstants.referenceSeparator + reference
    }
    
    private func recoverWriteKey(from reference: String) -> String? {
        return reference.components(separatedBy: DataStoreConstants.referenceSeparator).first
    }
}

/**
 Private variables and functions to manage incoming events.
 */

extension MemoryStore {
    private var currentDataItemKey: String {
        return DataStoreConstants.memoryIndex + self.writeKey
    }
    
    private var currentDataItemId: String? {
        guard let currentItemId: String = self.keyValueStore.read(reference: self.currentDataItemKey) else { return nil }
        return currentItemId
    }
    
    private var currentDataItem: EventDataItem? {
        guard let currentItemId = self.currentDataItemId else { return nil }
        return self.dataItems.filter { $0.reference == currentItemId }.first
    }
}

// MARK: - DataStore
/**
 Implementation of the `DataStore` protocol.
 */
extension MemoryStore: DataStore {
    func retain(value: String) async {
        await withCheckedContinuation { continuation in
            self.store(event: value)
            continuation.resume()
        }
    }
    
    func retrieve() async -> [EventDataItem] {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: self.collectDataItems())
        }
    }
    
    func remove(reference: String) async -> Bool {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: self.removeItem(using: reference))
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
