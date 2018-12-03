//
//  SVVoteViewController.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/3/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import CoreBluetooth

enum SVVoteVCType {
    case typeCreate // create new vote
    case typeVote // join a vote
}

enum deviceInfo {
    case central
    case peripheral
    case unknown
}

class SVVoteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {
    
    // consts
    private let DEVICE_HEIGHT = UIScreen.main.bounds.size.height
    private let DEVICE_WIDTH = UIScreen.main.bounds.size.width
    private var type:SVVoteVCType!
    
    lazy var voteTableView : UITableView = {
        let tableView = UITableView()
        tableView.register(SVVoteViewTitleTableViewCell.classForCoder(), forCellReuseIdentifier: SVVoteViewTitleTableViewCell.identifier())
        tableView.register(SVVoteViewDetailsTableViewCell.classForCoder(), forCellReuseIdentifier: SVVoteViewDetailsTableViewCell.identifier())
        tableView.register(SVVoteViewOptionTableViewCell.classForCoder(), forCellReuseIdentifier: SVVoteViewOptionTableViewCell.identifier())
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    lazy var actionBtn : UIButton = {
        let btn = UIButton()
        var title = ""
        if self.type == .typeCreate {
            title = "Create"
        } else if self.type == .typeVote {
            title = "Vote"
        }
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = UIColor(red: 67/255.0, green: 130/255.0, blue: 203/255.0, alpha: 1)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(actionBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    // current vote information
    var voteTitle : String = ""
    var voteDetail : String = ""
    var voteOptions = ["", "", "", ""]
    
    // current device information
    var deviceInfo : deviceInfo = .unknown
    
    // current vote selection
    var selection : Int?
    
    // MARK: life cycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(withType : SVVoteVCType) {
        self.init()
        self.type = withType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.addKVO()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        if self.type == .typeVote {
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
        self.tabBarController?.tabBar.isHidden = true
        if self.deviceInfo == .central {
            SVBLECentralManager.sharedManager.currVC = self
        } else if self.deviceInfo == .peripheral {
            SVBLEPeripheralManager.sharedManager.currVC = self
        }
    }
    
    // MARK: functionality
    func setupUI() {
        // navigation bar
        var title = ""
        if self.type == SVVoteVCType.typeCreate {
            title = "Create vote"
        } else if self.type == SVVoteVCType.typeVote {
            title = "Let's vote!"
        }
        
        self.title = title
        self.view.backgroundColor = .white
        
        // subviews
        self.view.addSubview(self.voteTableView)
        self.view.addSubview(self.actionBtn)
        
        // layout
        self.voteTableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(SVDevice.navigationBarOffset() + 30)
            make.left.equalTo(self.view).offset(30)
            make.right.equalTo(self.view).offset(-30)
            make.bottom.equalTo(self.actionBtn.snp.top).offset(-20)
        }
        
        self.actionBtn.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).offset(-50)
            make.left.right.equalTo(self.voteTableView)
            make.height.equalTo(30)
        }
    }
    
    // KVO
    func addKVO() {
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: "optionCell")
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.view.frame = CGRect(x: 0, y: 0 - 225, width: self.DEVICE_WIDTH, height: self.DEVICE_HEIGHT)
            self.actionBtn.isHidden = true
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame = CGRect(x: 0, y: 0, width: DEVICE_WIDTH, height: DEVICE_HEIGHT)
        self.actionBtn.isHidden = false
    }
    
    @objc func actionBtnPressed() {
        if self.type == .typeCreate {
            let voteDict : [String : Any] = ["title" : self.voteTitle, "detail" : self.voteDetail, "options" : self.voteOptions]
            let vc = SVVotePrepViewController()
            SVBLECentralManager.sharedManager.voteDict = voteDict as [String : Any]
            self.navigationController?.pushViewController(vc, animated: true)
        } else if self.type == .typeVote {
            if self.selection != nil {
                if self.deviceInfo == .central {
                    SVBLECentralManager.sharedManager.voteInfo[self.selection!] += 1
                    let vc = SVVoteResultViewController()
                    vc.deviceInfo = self.deviceInfo
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if self.deviceInfo == .peripheral {
                    SVBLEPeripheralManager.sharedManager.sendSelectionInfo(self.selection!)
                }
            }
        }
    }
    
    // MARK: UITableView Datasource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 4
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Title"
        case 1:
            return "Details"
        case 2:
            return "Options"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return self.voteTableView.frame.height / 12
        case 1:
            return self.voteTableView.frame.height / 12 * 3
        case 2:
            return (self.voteTableView.frame.height / 12 * 5.5) / 4
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell : SVVoteViewTitleTableViewCell? = tableView.dequeueReusableCell(withIdentifier: SVVoteViewTitleTableViewCell.identifier(), for: indexPath) as? SVVoteViewTitleTableViewCell
            if cell == nil {
                cell = SVVoteViewTitleTableViewCell.init(style: .default, reuseIdentifier: SVVoteViewTitleTableViewCell.identifier())
            }
            if self.type == .typeCreate {
                cell!.titleCellTransBlock = {
                    (title : String) in
                    self.voteTitle = title
                }
            } else if self.type == .typeVote {
                cell!.titleTextField.isUserInteractionEnabled = false
                cell!.titleTextField.textColor = .black
                if self.deviceInfo == .central {
                    if let title = SVBLECentralManager.sharedManager.voteDict["title"] as? String {
                        cell!.titleTextField.text = title
                    } else {
                        cell!.titleTextField.text = ""
                    }
                } else if self.deviceInfo == .peripheral {
                    if let title = SVBLEPeripheralManager.sharedManager.voteDict["title"] as? String {
                        cell!.titleTextField.text = title
                    } else {
                        cell!.titleTextField.text = ""
                    }
                }
            }
            return cell!
        } else if indexPath.section == 1 {
            var cell : SVVoteViewDetailsTableViewCell? = tableView.dequeueReusableCell(withIdentifier: SVVoteViewDetailsTableViewCell.identifier(), for: indexPath) as? SVVoteViewDetailsTableViewCell
            if cell == nil {
                cell = SVVoteViewDetailsTableViewCell.init(style: .default, reuseIdentifier: SVVoteViewDetailsTableViewCell.identifier())
            }
            if self.type == .typeCreate {
                cell!.detailCellTransBlock = {
                    (detail : String) in
                    self.voteDetail = detail
                }
            } else if self.type == .typeVote {
                cell!.detailTextView.isUserInteractionEnabled = false
                cell!.detailTextView.textColor = .black
                if self.deviceInfo == .central {
                    if let detail = SVBLECentralManager.sharedManager.voteDict["detail"] as? String {
                        cell!.detailTextView.text = detail
                    } else {
                        cell!.detailTextView.text = ""
                    }
                } else if self.deviceInfo == .peripheral {
                    if let detail = SVBLEPeripheralManager.sharedManager.voteDict["detail"] as? String {
                        cell!.detailTextView.text = detail
                    } else {
                        cell!.detailTextView.text = ""
                    }
                }
  
            }
            return cell!
        } else {
            var cell : SVVoteViewOptionTableViewCell? = tableView.dequeueReusableCell(withIdentifier: SVVoteViewOptionTableViewCell.identifier(), for: indexPath) as? SVVoteViewOptionTableViewCell
            if cell == nil {
                cell = SVVoteViewOptionTableViewCell.init(style: .default, reuseIdentifier: SVVoteViewOptionTableViewCell.identifier())
            }
            if self.type == .typeCreate {
                switch indexPath.row {
                case 0:
                    cell!.optionTextLabel.text = "A."
                    cell!.optionCellTransBlock = {
                        (option : String) in
                        self.voteOptions[0] = option
                    }
                case 1:
                    cell!.optionTextLabel.text = "B."
                    cell!.optionCellTransBlock = {
                        (option : String) in
                        self.voteOptions[1] = option
                    }
                case 2:
                    cell!.optionTextLabel.text = "C."
                    cell!.optionCellTransBlock = {
                        (option : String) in
                        self.voteOptions[2] = option
                    }
                case 3:
                    cell!.optionTextLabel.text = "D."
                    cell!.optionCellTransBlock = {
                        (option : String) in
                        self.voteOptions[3] = option
                    }
                default :
                    break
                }
            } else if self.type == .typeVote {
                cell!.optionTextField.isUserInteractionEnabled = false
                cell!.selectionStyle = .blue
                if self.deviceInfo == .central {
                    if let options = SVBLECentralManager.sharedManager.voteDict["options"] as? Array<String> {
                        switch indexPath.row {
                        case 0:
                            cell!.optionTextLabel.text = "A. " + options[0]
                        case 1:
                            cell!.optionTextLabel.text = "B. " + options[1]
                        case 2:
                            cell!.optionTextLabel.text = "C. " + options[2]
                        case 3:
                            cell!.optionTextLabel.text = "D. " + options[3]
                        default :
                            break
                        }
                    }
                } else if self.deviceInfo == .peripheral {
                    if let options = SVBLEPeripheralManager.sharedManager.voteDict["options"] as? Array<String> {
                        switch indexPath.row {
                        case 0:
                            cell!.optionTextLabel.text = "A. " + options[0]
                        case 1:
                            cell!.optionTextLabel.text = "B. " + options[1]
                        case 2:
                            cell!.optionTextLabel.text = "C. " + options[2]
                        case 3:
                            cell!.optionTextLabel.text = "D. " + options[3]
                        default :
                            break
                        }
                    }
                }
            }
            return cell!
        }
    }
    
    // MARK: UITableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            self.selection = indexPath.row
        }
    }
}
