//
//  buttonExtension.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-01.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

extension UIButton {
    
    func roundCorners(corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

}
