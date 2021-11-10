//
//  RSIntegrationFactory.swift
//  Rudder
//
//  Created by Pallab Maiti on 04/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc public protocol RSIntegrationFactory {
    func initiate(_ config: RSDestinationConfig?, client: RSClient, rudderConfig: RSConfig) -> RSIntegration
    
    var key: String { get }
}
