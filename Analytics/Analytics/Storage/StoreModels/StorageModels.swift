//
//  StorageModels.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/09/24.
//

import Foundation

public struct StorageResult: Codable {
    public let dataFiles: [URL]?
    public let dataItems: [EventDataItem]?
    
    private init(dataFiles: [URL]?, dataItems: [EventDataItem]?) {
        self.dataFiles = dataFiles
        self.dataItems = dataItems
    }
    
    public init(dataFiles: [URL]?) {
        self.init(dataFiles: dataFiles, dataItems: nil)
    }
    
    public init(dataItems: [EventDataItem]?) {
        self.init(dataFiles: nil, dataItems: dataItems)
    }
}

public struct EventDataItem: Codable {
    public let id: String
    public var batch: String
    public var isClosed: Bool
    
    init(batch: String) {
        self.id = UUID().uuidString
        self.batch = batch
        self.isClosed = false
    }
}
