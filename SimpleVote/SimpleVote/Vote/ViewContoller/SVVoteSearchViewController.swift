//
//  SVVoteSearchViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/18/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit
import CoreBluetooth

class SVVoteSearchViewController: UIViewController {
    
    lazy var statusLabel : UILabel = {
        let label = UILabel()
        if !SVBLEPeripheralManager.sharedManager.isConfigured {
            label.text = "Configuring..."
        } else {
            label.text = "Configured!\nPlease add me in the central device."
        }
        label.textColor = .black
        label.numberOfLines = 3
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        SVBLEPeripheralManager.sharedManager.currVC = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        self.tabBarController?.tabBar.isHidden = true
    }
    
    // MARK: functionality
    func setupUI() {
        self.view.backgroundColor = .white
        
        // subviews
        self.view .addSubview(self.statusLabel)
        
        // layout
        self.statusLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.view)
        }
    }
    
}
