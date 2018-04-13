//
//  passwordCell.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-11.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class passwordCell: UITableViewCell {
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
