//
//  StorageModels.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/09/24.
//

import Foundation

// MARK: - EventDataResult
/**
 Represents the result of processed event data items.

 This struct encapsulates a collection of `EventDataItem` objects, providing an organized structure for managing and accessing multiple data items at once.

 - Properties:
   - `dataItems`: An array of `EventDataItem` objects representing individual event batches.
 */
struct EventDataResult {
    /// An array of EventDataItem objects representing individual event batches.
    let dataItems: [EventDataItem]
}

// MARK: - EventDataItem
/**
 Represents a single event data item that contains a batch of events for processing.

 This struct is used to manage individual batches of events, including a unique reference identifier, the batch content, and whether the batch has been closed for further modifications.

 - Properties:
   - `reference`: A unique identifier for the event batch, generated as a UUID.
   - `batch`: The batch of events as a `String` that needs to be processed or uploaded.
   - `isClosed`: A flag indicating whether the batch is closed for further modifications.
*/
struct EventDataItem {
    /// A unique identifier for the event batch.
    var reference: String
    
    /// The batch of events as a `String`.
    var batch: String
    
    /// The status of the events batch as a `String`.
    var isClosed: Bool
    
    /**
     Initializes a new instance of `EventDataItem` with the provided batch content.
     
     - Parameter batch: The batch of events to be stored in this item.
     */
    init(batch: String) {
        self.reference = UUID().uuidString
        self.batch = batch
        self.isClosed = false
    }
}
