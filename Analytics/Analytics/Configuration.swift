//
//  Configuration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/08/24.
//

import UIKit

@objcMembers
public class Configuration {
    var writeKey: String
    var dataPlaneUrl: String
    var logger: Logger
    var optOut: Bool
    
    public init(writeKey: String, dataPlaneUrl: String, logger: Logger = SwiftLogger(logLevel: Constants.defaultLogLevel), optOut: Bool = false) {
        self.writeKey = writeKey
        self.dataPlaneUrl = dataPlaneUrl
        self.logger = logger
        self.optOut = optOut
    }
}
