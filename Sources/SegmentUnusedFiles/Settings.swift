//
//  Settings.swift
//  Segment
//
//  Created by Cody Garvin on 12/15/20.
//

import Foundation

/*struct Settings: Codable {
    var integrations: JSON? = nil
    var plan: JSON? = nil
    var edgeFunctions: JSON? = nil
    
    init(writeKey: String, apiHost: String) {
        integrations = try! JSON([
            SegmentDestination.Constants.integrationName.rawValue: [
                SegmentDestination.Constants.apiKey.rawValue: writeKey,
                SegmentDestination.Constants.apiHost.rawValue: apiHost
            ]
        ])
    }
    
    init(writeKey: String) {
        integrations = try! JSON([
            SegmentDestination.Constants.integrationName.rawValue: [
                SegmentDestination.Constants.apiKey.rawValue: writeKey,
                SegmentDestination.Constants.apiHost.rawValue: HTTPClient.getDefaultAPIHost()
            ]
        ])
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.integrations = try? values.decode(JSON.self, forKey: CodingKeys.integrations)
        self.plan = try? values.decode(JSON.self, forKey: CodingKeys.plan)
        self.edgeFunctions = try? values.decode(JSON.self, forKey: CodingKeys.edgeFunctions)
    }
    
    enum CodingKeys: String, CodingKey {
        case integrations
        case plan
        case edgeFunctions
    }
    
    /**
     * Easily retrieve settings for a specific integration name.
     *
     * - Parameter for: The string name of the integration
     * - Returns: The dictionary representing the settings for this integration as supplied by Segment.com
     */
    func integrationSettings(forKey key: String) -> [String: Any]? {
        guard let settings = integrations?.dictionaryValue else { return nil }
        let result = settings[key] as? [String: Any]
        return result
    }
    
    func integrationSettings<T: Codable>(forKey key: String) -> T? {
        var result: T? = nil
        guard let settings = integrations?.dictionaryValue else { return nil }
        if let dict = settings[key], let jsonData = try? JSONSerialization.data(withJSONObject: dict) {
            result = try? JSONDecoder().decode(T.self, from: jsonData)
        }
        return result
    }
    
    func integrationSettings<T: Codable>(forPlugin plugin: DestinationPlugin) -> T? {
        return integrationSettings(forKey: plugin.key)
    }
    
    func hasIntegrationSettings(forPlugin plugin: DestinationPlugin) -> Bool {
        return hasIntegrationSettings(key: plugin.key)
    }

    func hasIntegrationSettings(key: String) -> Bool {
        guard let settings = integrations?.dictionaryValue else { return false }
        return (settings[key] != nil)
    }
}

extension Settings: Equatable {
    static func == (lhs: Settings, rhs: Settings) -> Bool {
        let l = lhs.prettyPrint()
        let r = rhs.prettyPrint()
        return l == r
    }
}*/

