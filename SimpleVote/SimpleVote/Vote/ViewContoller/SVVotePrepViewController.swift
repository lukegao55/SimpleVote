//
//  SVVotePrepViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/18/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit
import CoreBluetooth

class SVVotePrepViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var voteDict : [String : Any] = [:]
    var selectedIdx = Set<Int>()
    
    lazy var deviceTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "aCell")
        tableView.isScrollEnabled = false
        tableView.allowsMultipleSelection = true
        return tableView
    }()
    
    lazy var searchBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Search", for: .normal)
        btn.backgroundColor = UIColor(red: 67/255.0, green: 130/255.0, blue: 203/255.0, alpha: 1)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(searchBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    lazy var connectBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Connect", for: .normal)
        btn.backgroundColor = UIColor(red: 67/255.0, green: 130/255.0, blue: 203/255.0, alpha: 1)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(connectBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SVBLECentralManager.sharedManager.currVC = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVBLECentralManager.sharedManager.stopScan()
    }
    
    // MARK: Functionality
    func setupUI() {
        self.view.backgroundColor = .white
        
        // Subviews
        self.view.addSubview(self.deviceTableView)
        self.view.addSubview(self.searchBtn)
        self.view.addSubview(self.connectBtn)
        
        // Layout
        self.deviceTableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(SVDevice.navigationBarOffset())
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.searchBtn.snp.top).offset(-20)
        }
        
        self.searchBtn.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.connectBtn.snp.top).offset(-20)
            make.left.equalTo(self.deviceTableView).offset(20)
            make.right.equalTo(self.deviceTableView).offset(-20)
            make.height.equalTo(30)
        }
        
        self.connectBtn.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).offset(-50)
            make.left.equalTo(self.deviceTableView).offset(20)
            make.right.equalTo(self.deviceTableView).offset(-20)
            make.height.equalTo(30)
        }
    }
    
    @objc func searchBtnPressed() {
        if !SVBLECentralManager.sharedManager.isScanning() {
            SVBLECentralManager.sharedManager.scan()
            self.searchBtn.setTitle("Stop", for: .normal)
            self.deviceTableView.isUserInteractionEnabled = false
        } else {
            SVBLECentralManager.sharedManager.stopScan()
            self.searchBtn.setTitle("Search", for: .normal)
            self.deviceTableView.isUserInteractionEnabled = true
        }
    }
    
    @objc func connectBtnPressed() {
        if selectedIdx.count != 0 {
            var peripherals : [CBPeripheral] = []
            for idx in self.selectedIdx {
                guard let peripheral = SVBLECentralManager.sharedManager.devicesDict[SVBLECentralManager.sharedManager.deviceNames[idx]] else {return}
                    peripherals.append(peripheral)
                }
            SVBLECentralManager.sharedManager.connect(peripherals)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "deviceNames" {
            self.deviceTableView.reloadData()
        }
    }
    
    // MARK:tableView datasource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SVBLECentralManager.sharedManager.deviceNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell? = tableView .dequeueReusableCell(withIdentifier: "aCell", for: indexPath)
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "aCell")
        }
        cell?.textLabel?.text = SVBLECentralManager.sharedManager.deviceNames[indexPath.row]
        cell?.selectionStyle = .blue
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Discovered users around you"
        }
        return ""
    }
    
    // MARK: tableView delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SVBLECentralManager.sharedManager.stopScan()
        self.selectedIdx.insert(indexPath.row)
        print(self.selectedIdx)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.selectedIdx.remove(indexPath.row)
        print(self.selectedIdx)
    }
    
}
