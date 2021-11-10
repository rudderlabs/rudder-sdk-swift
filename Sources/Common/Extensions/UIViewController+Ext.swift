//
//  UIViewController+Ext.swift
//  Rudder
//
//  Created by Pallab Maiti on 21/10/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import UIKit

extension UIViewController {
    static func rudderSwizzleView() {
        let originalSelector = #selector(viewDidAppear(_:))
        let swizzledSelector = #selector(rsViewDidAppear(_:))
        
        if let originalMethod = class_getInstanceMethod(self, originalSelector), let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) {
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    @objc
    func rsViewDidAppear(_ animated: Bool) {
        var name = NSStringFromClass(type(of: self))
        name = name.replacingOccurrences(of: "ViewController", with: "")
        RSClient.shared.screen(name, properties: ["automatic": true, "name": name])
        rsViewDidAppear(animated)
    }
}
