//
//  SimctlHelper.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

class SimctlHelper {

    // MARK: - Properties

    private(set) var pendingLocale: String?
}

// MARK: - Actions

extension SimctlHelper {

    func setLocale(_ identifier: String) {
        pendingLocale = identifier
    }

    func clearPendingLocale() {
        pendingLocale = nil
    }
}
