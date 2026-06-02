//
//  CustomLogger.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 22/04/25.
//

import Foundation
import RudderStackAnalytics

/**
 A basic implementation of the `Logger` protocol that prints analytics logs to the console.

 ## Usage:
 ```swift
 // Pass an instance as the logger when configuring the SDK
 let config = Configuration(writeKey: "WRITE_KEY", dataPlaneUrl: "DATA_PLANE_URL", logger: CustomLogger(), logLevel: .verbose)
 let analytics = Analytics(configuration: config)
 ```
 */

class CustomLogger: Logger {
    func verbose(log: String) {
        print("[Analytics-Swift] :: Verbose :: \(log)")
    }
    
    func debug(log: String) {
        print("[Analytics-Swift] :: Debug :: \(log)")
    }
    
    func info(log: String) {
        print("[Analytics-Swift] :: Info :: \(log)")
    }
    
    func warn(log: String) {
        print("[Analytics-Swift] :: Warn :: \(log)")
    }
    
    func error(log: String, error: (any Error)?) {
        print("[Analytics-Swift] :: Error :: \(log)")
        if let error {
            print("[Analytics-Swift] :: Error Details :: \(error)")
        }
    }
}
