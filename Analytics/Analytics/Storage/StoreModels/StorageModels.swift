//
//  StorageModels.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/09/24.
//

import Foundation

// MARK: - MessageDataResult
/**
 Represents the result of processed message data items.

 This struct encapsulates a collection of `MessageDataItem` objects, providing an organized structure for managing and accessing multiple data items at once.

 - Properties:
   - `dataItems`: An array of `MessageDataItem` objects representing individual message batches.
 */
public struct MessageDataResult {
    /// An array of MessageDataItem objects representing individual message batches.
    public let dataItems: [MessageDataItem]
    
    /**
     Initializes a new instance of `MessageDataResult` with the provided data items.
     
     - Parameter dataItems: An array of `MessageDataItem` objects.
     */
    init(dataItems: [MessageDataItem]) {
        self.dataItems = dataItems
    }
}

// MARK: - MessageDataItem
/**
 Represents a single message data item that contains a batch of messages for processing.

 This struct is used to manage individual batches of messages, including a unique reference identifier, the batch content, and whether the batch has been closed for further modifications.

 - Properties:
   - `reference`: A unique identifier for the message batch, generated as a UUID.
   - `batch`: The batch of messages as a `String` that needs to be processed or uploaded.
   - `isClosed`: A flag indicating whether the batch is closed for further modifications.
*/
public struct MessageDataItem {
    /// A unique identifier for the message batch.
    public var reference: String
    
    /// The batch of messages as a `String`.
    public var batch: String
    
    /// The batch of messages as a `String`.
    public var isClosed: Bool
    
    /**
     Initializes a new instance of `MessageDataItem` with the provided batch content.
     
     - Parameter batch: The batch of messages to be stored in this item.
     */
    init(batch: String) {
        self.reference = UUID().uuidString
        self.batch = batch
        self.isClosed = false
    }
}
