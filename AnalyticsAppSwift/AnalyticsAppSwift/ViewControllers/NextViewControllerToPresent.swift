//
//  NextViewControllerToPresent.swift
//  AnalyticsAppSwift
//
//  Created by Satheesh Kannan on 28/04/25.
//

import UIKit

// MARK: - NextViewControllerToPresent
/**
 View controller which will be presented.
 */
class NextViewControllerToPresent: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension NextViewControllerToPresent: UIKitScreenTrackable {
    func trackUIKitScreen(name: String) {
        AppDelegate.default.screen(name: name, category: "Presented Screen", properties: ["fullName": "NextViewControllerToPresent"])
    }
}
