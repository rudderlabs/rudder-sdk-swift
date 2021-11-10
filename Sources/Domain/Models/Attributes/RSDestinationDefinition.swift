//
//  RSDestinationDefinition.swift
//  Rudder
//
//  Created by Pallab Maiti on 17/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

struct RSDestinationDefinition: Codable {
    
    struct Config: Codable {
        let config: RSDestinationConfig?
        
        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case config
        }
    }
    
    private let _id: String?
    var id: String {
        return _id ?? ""
    }
    
    private let _name: String?
    var name: String {
        return _name ?? ""
    }    
    
    private let _displayName: String?
    var displayName: String {
        return _displayName ?? ""
    }
    
    private let _createdAt: String?
    var createdAt: String {
        return _createdAt ?? ""
    }
    
    private let _updatedAt: String?
    var updatedAt: String {
        return _updatedAt ?? ""
    }
    
    private let _destinationConfig: Config?
    var destinationConfig: RSDestinationConfig? {
        return _destinationConfig?.config
    }
    
    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case _name = "name"
        case _displayName = "displayName"
        case _createdAt = "createdAt"
        case _updatedAt = "updatedAt"
        case _destinationConfig = "config"
    }
}
