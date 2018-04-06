//
//  EventListCell.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-25.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class EventListCell: UITableViewCell {
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventTime: UILabel!
    @IBOutlet weak var eventTypeImage: UIImageViewX!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var badgeView: UIView!

    @IBOutlet weak var badgeLabel: UILabel!
    
 override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
