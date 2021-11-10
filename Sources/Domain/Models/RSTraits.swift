//
//  RSTraits.swift
//  Rudder
//
//  Created by Desu Sai Venkat on 12/08/21.
//

import Foundation

class RSTraits {
    var anonymousId: String?
    var age: String?
    var birthday: String?
    var createdAt: String?
    var description: String?
    var email: String?
    var firstName: String?
    var gender: String?
    var userId: String?
    var lastName: String?
    var name: String?
    var phone: String?
    var title: String?
    var userName: String?
    var extras: [String: Any]?
    var address: [String: Any]?
    var company: [String: Any]?
    
    init() {
        
    }
    
    init(dict: [String: Any]) {
        extras = dict
    }
    
    func dictionary() -> [String: Any] {
        var dictionary = [String: Any]()
        if let anonymousId = anonymousId {
            dictionary["anonymousId"] = anonymousId
        }
        return dictionary
    }
}
