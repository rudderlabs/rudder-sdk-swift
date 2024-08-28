//
//  SwiftLogger.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/08/24.
//

import UIKit

// MARK: - LogLevel
@objc
public enum LogLevel: Int {
    case none, debug, info, warn, error
}

// MARK: - Logger
public protocol Logger {
    var currentLogLevel: LogLevel { get }
    
    func activate(level: LogLevel)
    func info(tag: String, log: String)
    func debug(tag: String, log: String)
    func warn(tag: String, log: String)
    func error(tag: String, log: String)
}

public extension Logger {
    var currentLogLevel: LogLevel { get { .none } }
    
    func activate(level: LogLevel) {}
    func info(tag: String, log: String) {}
    func debug(tag: String, log: String) {}
    func warn(tag: String, log: String) {}
    func error(tag: String, log: String) {}
}

// MARK: - SwiftLogger
@objcMembers
public final class SwiftLogger: Logger {
    
    private var logLevel: LogLevel
    
    public init(logLevel: LogLevel) {
        self.logLevel = logLevel
    }
    
    public var currentLogLevel: LogLevel {
        get {
            return self.logLevel
        }
    }
    
    public func activate(level: LogLevel) {
        self.logLevel = level
    }
    
    public func info(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.info.rawValue {
            print(Constants.logTag + "-info : \(log)")
        }
    }
    
    public func debug(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.debug.rawValue {
            print(Constants.logTag + "-debug : \(log)")
        }
    }
    
    public func warn(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.warn.rawValue {
            print(Constants.logTag + "-warn : \(log)")
        }
    }
    
    public func error(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.error.rawValue {
            print(Constants.logTag + "-error : \(log)")
        }
    }
}

