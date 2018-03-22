//
//  FriendRequestTableCell.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-16.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class FriendRequestTableCell: UITableViewCell {

    @IBOutlet weak var acceptFriendButton: UIButton!
    @IBOutlet weak var rejectFriendButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    

}
