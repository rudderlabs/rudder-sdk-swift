//
//  RSBaseManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 25/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

protocol RSBaseManager {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
