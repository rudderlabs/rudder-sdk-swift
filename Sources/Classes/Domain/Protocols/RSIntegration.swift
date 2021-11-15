//
//  RSIntegration.swift
//  Rudder
//
//  Created by Pallab Maiti on 23/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc public protocol RSIntegration {
    func dump(_ message: RSMessage)
    func reset()
}
