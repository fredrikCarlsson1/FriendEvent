//
//  tableCell.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-15.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class TableCell: UITableViewCell {
    

    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}