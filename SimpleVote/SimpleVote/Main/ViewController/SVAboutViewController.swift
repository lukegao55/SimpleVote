//
//  SVAboutViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 12/2/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit

class SVAboutViewController: UIViewController {
    
    lazy var infoLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 4
        label.text = "For more info, please contact: \n eeshouhan@engineering.ucla.edu \n Open-sourced at: github.com/lukegao55"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.infoLabel)
        self.infoLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.view.snp.center)
        }
    }

}
