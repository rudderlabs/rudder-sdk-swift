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
    public static let logTag: String = "Rudder-Analytics"
    public static let defaultLogLevel: LogLevel = .none
    public static let defaultStorageMode: StorageMode = .disk
    public static let defaultControlPlaneUrl: String = "https://api.rudderlabs.com"
    public static let defaultGZipStatus: Bool = true
    public static let defaultFlushPolicies: [FlushPolicy] = [StartupFlushPolicy(), FrequencyFlushPolicy(), CountFlushPolicy()]
    
    //Internals
    static let fileIndex = "rudderstack.message.file.index."
    static let memoryIndex = "rudderstack.message.memory.index."
    static let maxPayloadSize: Int64 = 32 * 1024 //32kb
    static let maxBatchSize: Int64 = 500 * 1024 //500 kb
    static let fileType = "tmp"
    static let batchPrefix = "{\"batch\":["
    static let batchSentAtSuffix = "],\"sentAt\":\""
    static let batchSuffix = "\"}"
    // TODO: Version number updation will be automated in future..
    static let configQueryParams = ["p": "ios", "v": "1.29.1"]
    static let uploadSignal = "#!upload!#"
    
    private init() {}
}

public enum FlushEventCount: Int {
    case `default` = 30
    case min = 1
    case max = 100
}

public enum FlushInterval: Int {
    case `default` = 10_000 // 10 seconds..
    case min = 1
}

struct StorageKeys {
    static let anonymousId = "anonymous_id"
    static let sourceConfig = "source_config"
    
    private init() {}
}
