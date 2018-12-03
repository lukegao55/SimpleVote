//
//  SVVoteViewOptionTableViewCell.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/3/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit

class SVVoteViewOptionTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    var optionTextLabel = UILabel()
    
    lazy var optionTextField : UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.returnKeyType = .done
        textField.delegate = self
        return textField
    }()
    
    var optionCellTransBlock : (String) -> Void = {_ in}
    //  MARK: left cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init? (coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: functionality
    func setupUI() {
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.selectionStyle = .none
        
        // subview
        self.contentView.addSubview(self.optionTextLabel)
        self.contentView.addSubview(self.optionTextField)
        
        // layout
        self.optionTextLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(20)
            make.top.bottom.equalTo(self.contentView)
        }
        self.optionTextField.snp.makeConstraints { (make) in
            make.left.equalTo(self.optionTextLabel.snp.right).offset(20)
            make.right.equalTo(self.contentView).offset(-20)
            make.top.bottom.equalTo(self.contentView)
            make.width.greaterThanOrEqualTo(40)
        }
    }
    
    class func identifier() -> String {
        return String(describing:self)
    }
    
    // MARK: textField delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: "optionCell")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var option = ""
        if textField.text != nil {
            option = textField.text!
        }
        self.optionCellTransBlock(option)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
