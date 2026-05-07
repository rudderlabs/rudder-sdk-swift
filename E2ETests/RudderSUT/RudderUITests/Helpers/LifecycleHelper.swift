//
//  LifecycleHelper.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

class LifecycleHelper {

    // MARK: - Properties

    let app: XCUIApplication

    // MARK: - Init

    init(app: XCUIApplication) {
        self.app = app
    }
}

// MARK: - Lifecycle Actions

extension LifecycleHelper {

    func background() {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 0.5)
    }

    func foreground() {
        app.activate()
        Thread.sleep(forTimeInterval: 0.5)
    }

    func terminate() {
        app.terminate()
        Thread.sleep(forTimeInterval: 0.3)
    }

    func coldStart(locale: String? = nil) {
        app.terminate()
        Thread.sleep(forTimeInterval: 0.5)
        if let locale {
            app.launchArguments.removeAll { $0.hasPrefix("-Apple") }
            app.launchArguments += ["-AppleLanguages", "(\(locale))", "-AppleLocale", locale]
        }
        app.launch()
        Thread.sleep(forTimeInterval: 0.5)
    }
}
