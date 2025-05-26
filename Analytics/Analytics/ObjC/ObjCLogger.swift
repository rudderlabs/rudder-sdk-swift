//
//  ObjCLogger.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

@objc(RSLogger)
public protocol ObjCLogger {
    @objc optional func verbose(_ log: String)
    @objc optional func debug(_ log: String)
    @objc optional func info(_ log: String)
    @objc optional func warn(_ log: String)
    @objc optional func errorLog(_ log: String, error: Error?)
}

final class ObjCLoggerAdapter: Logger {
    private weak var objcLogger: ObjCLogger?

    public init(logger: ObjCLogger?) {
        self.objcLogger = logger
    }

    public func verbose(log: String) {
        objcLogger?.verbose?(log)
    }

    public func debug(log: String) {
        objcLogger?.debug?(log)
    }

    public func info(log: String) {
        objcLogger?.info?(log)
    }

    public func warn(log: String) {
        objcLogger?.warn?(log)
    }

    public func error(log: String, error: Error?) {
        objcLogger?.errorLog?(log, error: error)
    }
}
