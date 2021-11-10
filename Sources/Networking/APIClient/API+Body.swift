//
//  API+Body.swift
//  Rudder
//
//  Created by Pallab Maiti on 28/09/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

extension API {
    var httpBody: Data? {
        switch self {
        case .flushEvents(let params):
            return params.data(using: .utf8)
        case .downloadConfig:
            return nil
        }
    }
}
