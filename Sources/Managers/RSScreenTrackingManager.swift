//
//  RSScreenTrackingManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 23/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import UIKit

class RSScreenTrackingManager: RSTrackingManager {
    
    func track() {
        UIViewController.rudderSwizzleView()
    }
}
