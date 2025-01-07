//
//  UserIdentity.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/01/25.
//

import Foundation

public struct UserIdentity {
    var anonymousId = ""
    var userId = ""
    var traits = RudderTraits()
    var externalIds = [ExternalId]()
    
    static func initializeState(_ storage: KeyValueStorage) -> UserIdentity {
        var identity = UserIdentity()
        
        identity.anonymousId = storage.read(key: StorageKeys.anonymousId) ?? UUID().uuidString
        identity.userId = storage.read(key: StorageKeys.userId) ?? ""
        
        if let traitsString: String = storage.read(key: StorageKeys.traits), let traits = traitsString.toDictionary {
            identity.traits = traits
        }
        
        if let idArray: [String] = storage.read(key: StorageKeys.externalIds) {
            identity.externalIds = idArray.compactMap {
                guard let data = $0.utf8Data else { return nil }
                return try? JSONDecoder().decode(ExternalId.self, from: data) }
        }
        
        return identity
    }
}


public struct ExternalId: Codable {
    var type: String
    var id: String
}
