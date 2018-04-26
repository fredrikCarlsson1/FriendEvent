//
//  RoundedImage.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-26.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

    extension UIImageView {
        func roundCorners(corners:UIRectCorner, radius: CGFloat) {
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        }
}

extension UIView {
    func roundCorner(corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    
}








