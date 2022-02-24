//
//  RSIntegrationOperation.swift
//  Rudder
//
//  Created by Pallab Maiti on 08/09/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

struct RSIntegrationOperation {
    let integration: RSIntegration
    let key: String
    
    init(key: String, integration: RSIntegration) {
        self.key = key
        self.integration = integration
    }
}
