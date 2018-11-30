//
//  SVStartVotingViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/3/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit

class SVStartVotingViewController: UIViewController {
    
    var titleLabel:UILabel = {
        let label = UILabel()
        label.text = "Simple Bluetooth Voting"
        label.textColor = .black
        return label
    }()
    
    var createBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage.init(named: "newVoting.png"), for: .normal)
        btn.addTarget(self, action: #selector(createBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    var searchBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage.init(named: "searchHost.png"), for: .normal)
        btn.addTarget(self, action: #selector(searchBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    
    // MARK: functionality
    func setupUI()  {
        self.view.backgroundColor = .white
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.createBtn)
        self.view.addSubview(self.searchBtn)
        
        self.titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(100)
        }
        self.createBtn.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(100)
            //make.right.equalTo(self.view.snp.centerY).offset(-20)
        }
        self.searchBtn.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.view)
            make.right.equalTo(self.view).offset(-100)
            //make.left.equalTo(self.view.snp.centerY).offset(20)
        }
    }
    
    @objc func createBtnPressed() {
        let vc = SVVoteViewController.init(withType: .typeCreate)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func searchBtnPressed() {
        let vc = SVVoteSearchViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

}