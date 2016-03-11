//
//  func.swift
//  dueltime
//
//  Created by Pierre on 07/03/2016.
//  Copyright © 2016 Florent Taine. All rights reserved.
//

import Foundation
import UIKit


extension UIView {
    
    func addBackground(uimage : String) {
        // screen width and height:
        let width = UIScreen.mainScreen().bounds.size.width
        let height = UIScreen.mainScreen().bounds.size.height
        
        let imageViewBackground = UIImageView(frame: CGRectMake(0, 0, width, height))
        imageViewBackground.image = UIImage(named: uimage)
        
        // you can change the content mode:
        imageViewBackground.contentMode = UIViewContentMode.ScaleAspectFill
        
        self.addSubview(imageViewBackground)
        self.sendSubviewToBack(imageViewBackground)
    }
}

class myLabel : UILabel {
    override func layoutSubviews() {
        // 1. Get the label to set its frame correctly:
        super.layoutSubviews()
        
        // 2. Now the frame is set we can get the correct width
        // and set it to the preferredMaxLayoutWidth.
        self.preferredMaxLayoutWidth = self.frame.width
    }
}