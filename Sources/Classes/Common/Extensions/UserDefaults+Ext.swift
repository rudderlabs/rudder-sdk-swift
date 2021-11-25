//
//  UserDefaults+Ext.swift
//  Rudder
//
//  Created by Pallab Maiti on 13/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

extension PropertyListDecoder {
    func optionalDecode<T: Decodable>(_ type: T.Type, from object: Any?) -> T? {
        if let data = object as? Data {
            return try? PropertyListDecoder().decode(T.self, from: data)
        }
        return nil
    }
}

extension UserDefaults {
    var serverConfig: RSServerConfig? {
        get {
            return PropertyListDecoder().optionalDecode(RSServerConfig.self, from: object(forKey: RSConstants.RSServerConfigKey))
        }
        set {
            if let newValue = newValue {
                set(try? PropertyListEncoder().encode(newValue), forKey: RSConstants.RSServerConfigKey)
            } else {
                set(nil, forKey: RSConstants.RSServerConfigKey)
            }
        }
    }
    
    var lastUpdateTime: Int? {
        get { integer(forKey: RSConstants.RSServerLastUpdatedKey) }
        set { setValue(newValue, forKey: RSConstants.RSServerLastUpdatedKey) }
    }
    
    var traits: String? {
        get { string(forKey: RSConstants.RSTraitsKey) }
        set { setValue(newValue, forKey: RSConstants.RSTraitsKey) }
    }
    
    var buildVersionCode: String? {
        get { string(forKey: RSConstants.RSApplicationInfoKey) }
        set { setValue(newValue, forKey: RSConstants.RSApplicationInfoKey) }
    }
    
    var externalIds: String? {
        get { string(forKey: RSConstants.RSExternalIdKey) }
        set { setValue(newValue, forKey: RSConstants.RSExternalIdKey) }
    }
    
    var anonymousId: String? {
        get { string(forKey: RSConstants.RSAnonymousIdKey) }
        set { setValue(newValue, forKey: RSConstants.RSAnonymousIdKey) }
    }
    
    var optStatus: Bool? {
        get { bool(forKey: RSConstants.RSOptStatusKey) }
        set { setValue(newValue, forKey: RSConstants.RSOptStatusKey) }
    }
    
    var optInTime: Int? {
        get { integer(forKey: RSConstants.RSOptInTimeKey) }
        set { setValue(newValue, forKey: RSConstants.RSOptInTimeKey) }
    }
    
    var optOutTime: Int? {
        get { integer(forKey: RSConstants.RSOptOutTimeKey) }
        set { setValue(newValue, forKey: RSConstants.RSOptOutTimeKey) }
    }
}
