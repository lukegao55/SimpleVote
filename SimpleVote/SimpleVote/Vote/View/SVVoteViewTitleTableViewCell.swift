//
//  SVVoteViewTitleTableViewCell.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/10/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit

class SVVoteViewTitleTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    private let titlePlaceHolder = " Title"

    lazy var titleTextField : UITextField = {
        let textField = UITextField()
        textField.text = self.titlePlaceHolder
        textField.textColor = .gray
        textField.returnKeyType = .done
        textField.delegate = self
        
        return textField
    }()
    
    var titleCellTransBlock : (String) -> Void = {_ in}
    
    //  MARK: life cycle
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
        
        // detailTextView

        self.contentView.addSubview(self.titleTextField)
        
        // layout:
        self.titleTextField.snp.makeConstraints { (make) in
            make.top.right.left.bottom.equalTo(self.contentView)
        }
    }
    
    class func identifier() -> String {
        return String(describing:self)
    }
    
    // MARK: textField delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
        if textField.text == self.titlePlaceHolder {
            textField.text = ""
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            textField.text = self.titlePlaceHolder
            textField.textColor = .gray
        } else {
            guard let title = textField.text else {return}
            self.titleCellTransBlock(title)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
