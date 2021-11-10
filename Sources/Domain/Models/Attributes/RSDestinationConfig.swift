//
//  RSDestinationConfig.swift
//  Rudder
//
//  Created by Pallab Maiti on 19/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc open class RSDestinationConfig: NSObject, Codable {    
    struct Config: Codable {
        let ios: [String]?
        let unity: [String]?
        let android: [String]?
        let reactnative: [String]?
        let defaultConfig: [String]?
    }
    
    private let _destConfig: Config?
    var ios: [String]? {
        return _destConfig?.ios
    }
    
    var unity: [String]? {
        return _destConfig?.unity
    }
    
    var android: [String]? {
        return _destConfig?.android
    }
    
    var reactnative: [String]? {
        return _destConfig?.reactnative
    }
    
    var defaultConfig: [String]? {
        return _destConfig?.defaultConfig
    }
    
    let secretKeys: [String]?
    let excludeKeys: [String]?
    let includeKeys: [String]?
    
    private let _transformAt: String?
    var transformAt: String {
        return _transformAt ?? ""
    }
    
    private let _transformAt1: String?
    var transformAt1: String {
        return _transformAt1 ?? ""
    }
    
    let supportedSourceTypes: [String]?
    
    private let _saveDestinationResponse: Bool?
    var saveDestinationResponse: Bool {
        return _saveDestinationResponse ?? false
    }
    
    enum CodingKeys: String, CodingKey {
        case _destConfig = "config"
        case secretKeys, excludeKeys, includeKeys, supportedSourceTypes
        case _transformAt = "transformAt"
        case _transformAt1 = "transformAt1"
        case _saveDestinationResponse = "saveDestinationResponse"
    }
}
