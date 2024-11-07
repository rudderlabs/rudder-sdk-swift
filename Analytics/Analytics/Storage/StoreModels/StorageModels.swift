//
//  StorageModels.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/09/24.
//

import Foundation

// MARK: - MessageDataResult
/**
 A data model that contains the stored message event data.
 */
public struct MessageDataResult {
    public let dataItems: [MessageDataItem]
    
    init(dataItems: [MessageDataItem]) {
        self.dataItems = dataItems
    }
}

// MARK: - MessageDataItem
/**
 A data model which is used to handle the incoming message event data.
 */
public struct MessageDataItem {
    public var reference: String
    public var batch: String
    public var isClosed: Bool
    
    init(batch: String) {
        self.reference = UUID().uuidString
        self.batch = batch
        self.isClosed = false
    }
}
