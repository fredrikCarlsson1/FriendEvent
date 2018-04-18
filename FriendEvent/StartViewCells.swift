//
//  StartViewCells.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-06.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class StartViewCells: UITableViewCell {
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageViewX!
    @IBOutlet weak var sendPrivateMessageButton: UIButtonX!

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
     //   sendPrivateMessageButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
