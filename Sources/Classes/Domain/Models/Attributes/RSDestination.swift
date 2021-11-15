//
//  RSDestination.swift
//  Rudder
//
//  Created by Pallab Maiti on 17/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

struct RSDestination: Codable {
    let config: [String: String]?
    let secretConfig: [String: String]?
    
    private let _id: String?
    var id: String {
        return _id ?? ""
    }

    private let _name: String?
    var name: String {
        return _name ?? ""
    }

    private let _enabled: Bool?
    var enabled: Bool {
        return _enabled ?? false
    }
    
    private let _workspaceId: String?
    var workspaceId: String {
        return _workspaceId ?? ""
    }
    
    private let _deleted: Bool?
    var deleted: Bool {
        return _deleted ?? false
    }
    
    private let _createdAt: String?
    var createdAt: String {
        return _createdAt ?? ""
    }
    
    private let _updatedAt: String?
    var updatedAt: String {
        return _updatedAt ?? ""
    }

    let destinationDefinition: RSDestinationDefinition?
    
    enum CodingKeys: String, CodingKey {
        case config, secretConfig
        case _id = "id"
        case _name = "name"
        case _enabled = "enabled"
        case _workspaceId = "workspaceId"
        case _deleted = "deleted"
        case _createdAt = "createdAt"
        case _updatedAt = "updatedAt"
        case destinationDefinition
    }
}
