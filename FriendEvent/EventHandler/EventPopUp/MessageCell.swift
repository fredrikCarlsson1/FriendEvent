//
//  MessageCell.swift
//  
//
//  Created by Fredrik Carlsson on 2018-04-03.
//

import UIKit

class MessageCell: UICollectionViewCell {
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    
    let textView: UITextView = {
        let tV = UITextView()
        tV.text = "Sample text"
        tV.font = UIFont.systemFont(ofSize: 14)
        tV.translatesAutoresizingMaskIntoConstraints = false
        tV.backgroundColor = UIColor.clear
        tV.isEditable = false
        tV.isScrollEnabled = false
        return tV
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    let userLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        
    }()
    
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    var greyTopAnchor: NSLayoutConstraint?
    var blueTopAnchor: NSLayoutConstraint?
    var userLabelRightAnchor: NSLayoutConstraint?
    var userLabelLeftAnchor: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(userLabel)
        
        
        userLabelRightAnchor = userLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant:
            -22)
        userLabelRightAnchor?.isActive = false
        
        userLabelLeftAnchor = userLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 18)
        userLabelLeftAnchor?.isActive = true
        
        userLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        userLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        userLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        
        bubbleViewRightAnchor?.isActive = true
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 12)
        
        bubbleViewLeftAnchor?.isActive = false
        
        blueTopAnchor = bubbleView.topAnchor.constraint(equalTo: userLabel.bottomAnchor)
        blueTopAnchor?.isActive = true
        
        greyTopAnchor = bubbleView.topAnchor.constraint(equalTo: userLabel.bottomAnchor)
        greyTopAnchor?.isActive = false
        
        
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -25).isActive = true
        
        
        
        
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        
        textView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        
        textView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
    }
    
    
    
}
