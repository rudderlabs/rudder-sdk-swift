//
//  FlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 29/10/24.
//

import Foundation

public protocol FlushPolicy {
    func shouldFlush() -> Bool
}
