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
        naviVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "main"), selectedImage: UIImage(named: "main"))
        return naviVC
    }()
    
    let secondVC : UIViewController = {
        let vc = SVAboutViewController()
        vc.view.backgroundColor = .white
        vc.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "about"), selectedImage: UIImage(named: "about"))
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChild(self.firstVC)
        self.addChild(self.secondVC)
   
    }
}

