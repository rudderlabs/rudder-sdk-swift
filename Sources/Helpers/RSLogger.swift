//
//  RSLogger.swift
//  Rudder
//
//  Created by Pallab Maiti on 12/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc
open class RSLogger: NSObject {
    
    var logLevel: RSLogLevel
    
    override init() {
        logLevel = .error
    }
    
    func configure(logLevel: RSLogLevel) {
        self.logLevel = logLevel
    }
    
    @objc
    public static func logVerbose(_ message: String) {
        if RSClient.shared.logger.logLevel == .verbose {
            print("\(RSConstants.TAG):Verbose:\(message)")
        }
    }
    
    @objc
    public static func logDebug(_ message: String) {
        if RSClient.shared.logger.logLevel == .debug {
            print("\(RSConstants.TAG):Debug:\(message)")
        }
    }
    
    @objc
    public static func logInfo(_ message: String) {
        if RSClient.shared.logger.logLevel == .info {
            print("\(RSConstants.TAG):Info:\(message)")
        }
    }
    
    @objc
    public static func logWarn(_ message: String) {
        if RSClient.shared.logger.logLevel == .warning {
            print("\(RSConstants.TAG):Warn:\(message)")
        }
    }
    
    @objc
    public static func logError(_ message: String) {
        if RSClient.shared.logger.logLevel == .error {
            print("\(RSConstants.TAG):Error:\(message)")
        }
    }
}
