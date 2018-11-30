//
//  SVVoteViewDetailsTableViewCell.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/10/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import SnapKit

class SVVoteViewDetailsTableViewCell: UITableViewCell, UITextViewDelegate {
    
    private let detailPlaceHolder = " Details"

    lazy var detailTextView : UITextView = {
        let textView = UITextView()
        textView.text = self.detailPlaceHolder
        textView.textColor = .gray
        textView.returnKeyType = .done
        textView.delegate = self
        
        return textView
    }()
    
    var detailCellTransBlock : (String) -> Void = {_ in}
    
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
        
        // detailTextView
        self.contentView.addSubview(self.detailTextView)
        
        // layout
        self.detailTextView.snp.makeConstraints { (make) in
            make.top.right.left.bottom.equalTo(self.contentView)
        }
    }
    
    class func identifier() -> String {
        return String(describing:self)
    }
    
    // MARK: textView delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = .black
        if textView.text == self.detailPlaceHolder {
            textView.text = ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = self.detailPlaceHolder
            textView.textColor = .gray
        } else {
            guard let detail = textView.text else {return}
            self.detailCellTransBlock(detail)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
}
