//
//  BluetoothStatusManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 21/12/24.
//

import Foundation
import CoreBluetooth

/**
 This class will be used to check the availability status of Bluetooth.
 */
final class BluetoothStatusManager: NSObject, CBCentralManagerDelegate {
    var isBluetoothEnabled = false
    
    var isBluetoothAvailable: Bool {
        return CBManager.authorization == .allowedAlways
    }
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.isBluetoothEnabled = central.state == .poweredOn
    }
}
