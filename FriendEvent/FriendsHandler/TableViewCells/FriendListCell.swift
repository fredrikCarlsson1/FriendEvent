//
//  FriendListCell.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-06.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class FriendListCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageViewX!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImage.layer.cornerRadius = 25
        profileImage.layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
