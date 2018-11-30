//
//  MainViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/3/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit

class SVMainTabbarController: UITabBarController {
    let firstVC : SVRootNavigationController = {
        let vc = SVStartVotingViewController()
        let naviVC = SVRootNavigationController(rootViewController: vc)
        naviVC.tabBarItem.title = "Main"
        return naviVC
    }()
    
    let secondVC : UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        vc.tabBarItem.title = "About"
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChild(self.firstVC)
        self.addChild(self.secondVC)
    }
}
