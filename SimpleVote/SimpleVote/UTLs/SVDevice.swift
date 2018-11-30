//
//  SVDevice.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/3/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit

class SVDevice: NSObject {
    
    class func isIPhoneX() -> Bool {
        if UIScreen.main.bounds.height == 812 {
            return true
        }
        return false
    }
    
    class func navigationBarOffset() -> Float {
        if self.isIPhoneX() {
            return 88
        } else {
            return 64
        }
    }
    
}
