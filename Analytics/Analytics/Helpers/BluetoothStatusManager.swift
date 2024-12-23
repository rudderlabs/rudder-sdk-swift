//
//  BluetoothStatusManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 21/12/24.
//

import Foundation
import CoreBluetooth

final class BluetoothStatusManager: NSObject, CBCentralManagerDelegate {
    var isBluetoothEnabled = false
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.isBluetoothEnabled = central.state == .poweredOn
    }
}
