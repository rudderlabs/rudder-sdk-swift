//
//  VendorSystem.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

internal struct ScreenSize {
    let width: Double
    let height: Double
    let density: Double
}

internal enum ConnectionType {
    case cellular
    case wifi
    case bluetooth
}

internal enum ConnectionStatus {
    case offline
    case online(ConnectionType)
    case unknown
}

internal class VendorSystem {
    var manufacturer: String {
        return "unknown"
    }
    
    var type: String {
        return "unknown"
    }
    
    var model: String {
        return "unknown"
    }
    
    var name: String {
        return "unknown"
    }
    
    var identifierForVendor: String? {
        return nil
    }
    
    var systemName: String {
        return "unknown"
    }
    
    var systemVersion: String {
        return ""
    }
    
    var screenSize: ScreenSize {
        return ScreenSize(width: 0, height: 0, density: 0)
    }
    
    var connection: ConnectionStatus {
        return ConnectionStatus.unknown
    }
    
    var requiredPlugins: [PlatformPlugin] {
        return []
    }
    
    var carrier: String {
        return "unavailable"
    }
    
    static var current: VendorSystem = {
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        return iOSVendorSystem()
        #elseif os(macOS)
        return MacOSVendorSystem()
        #elseif os(watchOS)
        return watchOSVendorSystem()
        #else
        return VendorSystem()
        #endif
    }()
}
