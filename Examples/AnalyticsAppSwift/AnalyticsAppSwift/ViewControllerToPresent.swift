//
//  ViewControllerToPresent.swift
//  AnalyticsAppSwift
//
//  Created by Satheesh Kannan on 28/04/25.
//

import UIKit

// MARK: - ViewControllerToPresent
/**
 View controller which will be presented.
 */
class ViewControllerToPresent: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
