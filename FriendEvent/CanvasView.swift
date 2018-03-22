//
//  CanvasView.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-21.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import Foundation

class CanvasView: UIView {
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext(){
            context.setStrokeColor(UIColor.magenta.cgColor)
            context.setLineWidth(10)
            context.beginPath()
            context.move(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: 140, y: 123))
            context.addLine(to: CGPoint(x: 540, y: 903))
            context.strokePath()
            
        }
    }
    
}
