//
//  ViewControllerToPush.swift
//  AnalyticsAppSwift
//
//  Created by Satheesh Kannan on 28/04/25.
//

import UIKit

// MARK: - ViewControllerToPush

class ViewControllerToPush: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
