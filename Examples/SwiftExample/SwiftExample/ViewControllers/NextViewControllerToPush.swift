//
//  NextViewControllerToPush.swift
//  SwiftExample
//
//  Created by Satheesh Kannan on 28/04/25.
//

import UIKit

// MARK: - NextViewControllerToPush
/**
 View controller which will be pushed using `UINavigationController`.
 */
class NextViewControllerToPush: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
