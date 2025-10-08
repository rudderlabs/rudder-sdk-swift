//
//  DestinationResult.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 08/10/25.
//

import Foundation

// MARK: - DestinationResult
/**
 Represents the result of a destination initialization operation.
 */
public enum DestinationResult {
    /// Represents a successful destination initialization.
    case success
    
    /// Represents a failed destination initialization with an associated error.
    case failure(Error)
    
    /**
     Returns `true` if the result represents a success, `false` otherwise.
     */
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /**
     Returns `true` if the result represents a failure, `false` otherwise.
     */
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /**
     Returns the error if the result is a failure, `nil` otherwise.
     */
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
