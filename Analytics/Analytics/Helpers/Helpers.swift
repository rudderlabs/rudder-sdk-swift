//
//  Helpers.swift
//  Analytics
//
//  Created by Satheesh Kannan on 26/08/24.
//

import Foundation

// MARK: - Typealiases(Public)
public typealias RudderOptions = [String: Any]
public typealias RudderProperties = [String: Any]
public typealias VoidClosure = () -> Void

// MARK: - Typealiases(Internal)
typealias PluginClosure = (Plugin) -> Void

// MARK: - Constants
public struct Constants {
    public static let logTag = "Rudder-Analytics"
    public static let defaultLogLevel: LogLevel = .none
    public static let defaultStorageMode: StorageMode = .disk
    public static let defaultControlPlaneUrl = "https://api.rudderlabs.com"
    public static let defaultGZipStatus = true
    
    //Internals
    static let fileIndex = "rudderstack.message.file.index."
    static let memoryIndex = "rudderstack.message.memory.index."
    static let maxPayloadSize: Int64 = 32 * 1024 //32kb
    static let maxBatchSize: Int64 = 500 * 1024 //500 kb
    static let fileType = "tmp"
    static let batchPrefix = "{\"batch\":["
    static let batchSentAtSuffix = "],\"sentAt\":\""
    static let batchSuffix = "\"}"
    static let configQueryParams = ["p": "ios", "v": "1.29.1"]
    static let uploadSignal = "#!upload!#"
    
    private init() {}
}

struct StorageKeys {
    static let anonymousId = "anonymous_id"
    static let sourceConfig = "source_config"
    
    private init() {}
}
