//
//  CustomLogger.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 22/04/25.
//

import Foundation
import Analytics

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
