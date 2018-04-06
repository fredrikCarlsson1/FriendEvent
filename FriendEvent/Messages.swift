//
//  Messages.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-03.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import Foundation

class Messages {
    var ID: String
    var message: String
    var timeStamp: Int
    
    init(id: String, message: String, timeStamp: Int) {
        self.ID = id
        self.message = message
        self.timeStamp = timeStamp
    }
    
}
