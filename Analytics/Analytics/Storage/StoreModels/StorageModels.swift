//
//  StorageModels.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/09/24.
//

import Foundation

public struct MessageDataResult {
    public let dataFiles: [URL]?
    public let dataItems: [MessageDataItem]?
    
    private init(dataFiles: [URL]?, dataItems: [MessageDataItem]?) {
        self.dataFiles = dataFiles
        self.dataItems = dataItems
    }
    
    public init(dataFiles: [URL]?) {
        self.init(dataFiles: dataFiles, dataItems: nil)
    }
    
    public init(dataItems: [MessageDataItem]?) {
        self.init(dataFiles: nil, dataItems: dataItems)
    }
}

public struct MessageDataItem {
    public let id: String
    public var batch: String
    public var isClosed: Bool
    
    init(batch: String) {
        self.id = UUID().uuidString
        self.batch = batch
        self.isClosed = false
    }
}
