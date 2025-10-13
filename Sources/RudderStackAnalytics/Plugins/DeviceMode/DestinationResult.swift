//
//  DestinationResult.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 13/10/25.
//

import Foundation

/**
 Represents the result of a destination initialization operation.
 */
public enum DestinationResult {
    /// Represents a successful destination initialization.
    case success
    
    /// Represents a failed destination initialization with an associated error.
    case failure(Error)
}
