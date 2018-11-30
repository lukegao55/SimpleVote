//
//  SVVoteResultViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/24/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit

class SVVoteResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // consts
    private let DEVICE_HEIGHT = UIScreen.main.bounds.size.height
    private let DEVICE_WIDTH = UIScreen.main.bounds.size.width
    
    lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        if self.deviceInfo == .central {
            if let title = SVBLECentralManager.sharedManager.voteDict["title"] as! String? {
                label.text = title
            }
        } else if self.deviceInfo == .peripheral {
            if let title = SVBLEPeripheralManager.sharedManager.voteDict["title"] as! String? {
                label.text = title
            }
        }
        return label
    }()
    
    lazy var resultTableView : UITableView = {
        let tableView = UITableView()
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(SVVoteResultViewResultTableViewCell.classForCoder(), forCellReuseIdentifier: SVVoteResultViewResultTableViewCell.identifier())
        return tableView
    }()
    
    lazy var statusLabel : UILabel = {
        let label = UILabel()
        label.text = "Waiting for responses..."
        label.textAlignment = .center
        return label
    }()
    
    lazy var actionBtn : UIButton = {
        let btn = UIButton()
        if self.deviceInfo == .central {
            btn.setTitle("Reveal results", for: .normal)
        } else if self.deviceInfo == .peripheral {
            btn.setTitle("End vote", for: .normal)
        }
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(actionBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    var options = ["", "", "", ""]
    var deviceInfo : deviceInfo = .unknown
    var isResultShown = false
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        if self.deviceInfo == .central {
            self.options = SVBLECentralManager.sharedManager.voteDict["options"] as! Array<String>
        } else if self.deviceInfo == .peripheral {
            self.options = SVBLEPeripheralManager.sharedManager.voteDict["options"] as! Array<String>
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        if self.deviceInfo == .central {
            SVBLECentralManager.sharedManager.currVC = self
            if SVBLECentralManager.sharedManager.receiveVotes == SVBLECentralManager.sharedManager.connectedDevices.count {
                self.didFinishVote()
            }
        } else if self.deviceInfo == .peripheral {
            SVBLEPeripheralManager.sharedManager.currVC = self
        }
    }
    
    // MARK: funcionality
    func setupUI()  {
        self.view.backgroundColor = .white

        // subviews
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.resultTableView)
        self.view.addSubview(self.statusLabel)
        
        // layout
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(DEVICE_HEIGHT / 4)
            make.left.right.equalTo(self.view)
        }
        self.resultTableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(30)
            make.left.equalTo(self.view).offset(30)
            make.right.equalTo(self.view).offset(-30)
            make.height.equalTo(DEVICE_HEIGHT / 3)
        }
        self.statusLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.resultTableView.snp.bottom).offset(50)
            make.left.right.equalTo(self.resultTableView)
        }
    }
    
    func didFinishVote() {
        if self.deviceInfo == . central {
            self.statusLabel.removeFromSuperview()
            self.view.addSubview(self.actionBtn)
            self.actionBtn.snp.makeConstraints { (make) in
                make.top.equalTo(self.resultTableView.snp.bottom).offset(50)
                make.left.right.equalTo(self.resultTableView)
            }
        }
    }
    
    func didReceiveResult() {
        if self.deviceInfo == .peripheral {
            self.statusLabel.removeFromSuperview()
            self.view.addSubview(self.actionBtn)
            self.actionBtn.snp.makeConstraints { (make) in
                make.top.equalTo(self.resultTableView.snp.bottom).offset(50)
                make.left.right.equalTo(self.resultTableView)
            }
            for i in 0...3 {
                if let cell = self.resultTableView.cellForRow(at: IndexPath(row: i, section: 0)) as? SVVoteResultViewResultTableViewCell {
                    cell.counterLabel.text = String(SVBLEPeripheralManager.sharedManager.voteInfo[i])
                }
            }
            self.resultTableView.reloadData()
            self.isResultShown = true
        }
    }
    
    @objc func actionBtnPressed() {
        if !self.isResultShown && self.deviceInfo == .central {
            for i in 0...3 {
                if let cell = self.resultTableView.cellForRow(at: IndexPath(row: i, section: 0)) as? SVVoteResultViewResultTableViewCell {
                    cell.counterLabel.text = String(SVBLECentralManager.sharedManager.voteInfo[i])
                }
            }
            self.resultTableView.reloadData()
            self.isResultShown = true
            self.actionBtn.setTitle("End vote", for: .normal)
            if self.deviceInfo == .central {
                SVBLECentralManager.sharedManager.boardcastResult()
            }
        } else {
            if self.deviceInfo == .central {
                SVBLECentralManager.sharedManager.reset()
            } else if self.deviceInfo == .peripheral {
                SVBLEPeripheralManager.sharedManager.reset()
            }
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    // MARK: TableView Datasource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (tableView.frame.height) / 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {var cell : SVVoteResultViewResultTableViewCell? = tableView.dequeueReusableCell(withIdentifier: SVVoteResultViewResultTableViewCell.identifier(), for: indexPath) as? SVVoteResultViewResultTableViewCell
        if cell == nil {
            cell = SVVoteResultViewResultTableViewCell.init(style: .default, reuseIdentifier: SVVoteResultViewResultTableViewCell.identifier())
        }
        switch indexPath.row {
        case 0:
            cell!.optionTextLabel.text = "A. "
            cell!.optionTextField.text = self.options[0]
        case 1:
            cell!.optionTextLabel.text = "B. "
            cell!.optionTextField.text = self.options[1]
        case 2:
            cell!.optionTextLabel.text = "C. "
            cell!.optionTextField.text = self.options[2]
        case 3:
            cell!.optionTextLabel.text = "D. "
            cell!.optionTextField.text = self.options[3]
        default:
            break
        }
        return cell!
    }

}
