//
//  BaseViewController.swift
//  SwiftExample
//
//  Created by Satheesh Kannan on 19/04/25.
//

import UIKit

// MARK: - BaseViewController

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Analytics App Swift"
    }
    
}

// MARK: - Button Actions

extension BaseViewController {

    @IBAction func trackEvent(_ sender: Any) {
        AppDelegate.default.track(name: "Button Clicked")
    }
    
    @IBAction func pushViewController(_ sender: Any) {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: "ViewControllerToPush")
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func presentViewController(_ sender: Any) {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: "ViewControllerToPresent")
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true)
    }
}

