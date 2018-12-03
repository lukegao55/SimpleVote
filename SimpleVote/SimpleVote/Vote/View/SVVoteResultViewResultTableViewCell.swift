//
//  SVVoteResultViewResultTableViewCell.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/25/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit

class SVVoteResultViewResultTableViewCell: SVVoteViewOptionTableViewCell {
    
    lazy var counterLabel = UILabel()
    
    // MARK: life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init? (coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: functionality
    override func setupUI() {

        self.selectionStyle = .none
        
        // subview
        self.contentView.addSubview(self.optionTextLabel)
        self.contentView.addSubview(self.optionTextField)
        self.contentView.addSubview(self.counterLabel)
        self.counterLabel.textColor = .black
        
        // layout
        self.optionTextLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(20)
            make.top.bottom.equalTo(self.contentView)
        }
        self.optionTextField.snp.makeConstraints { (make) in
            make.left.equalTo(self.optionTextLabel.snp.right).offset(20)
            make.right.equalTo(self.counterLabel).offset(-20)
            make.width.greaterThanOrEqualTo(50)
            make.top.bottom.equalTo(self.contentView)
        }
        self.counterLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView).offset(-10)
            make.top.bottom.equalTo(self.optionTextField)
        }
    }
    
    override class func identifier() -> String {
        return String(describing:self)
    }

}
