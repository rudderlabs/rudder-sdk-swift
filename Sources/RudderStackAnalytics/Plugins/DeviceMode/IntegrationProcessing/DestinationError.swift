//
//  DestinationError.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 28/10/25.
//

import Foundation

/**
 Represents an `Error` which occurs when the destination present in an integration fails to initialise or update using the source configuration.
 */
enum DestinationError: Error {
    case destinationNotReady(String)
    case destinationNotFound(String)
    case destinationDisabled(String)
    
    var errorDescription: String {
        switch self {
        case .destinationNotReady(let destination):
            return "Destination \(destination) is absent or disabled in dashboard."
        case .destinationNotFound(let destination):
            return "Destination \(destination) not found in the source config. No events will be sent to this destination."
        case .destinationDisabled(let destination):
            return "Destination \(destination) is disabled in dashboard. No events will be sent to this destination."
        }
    }
}
