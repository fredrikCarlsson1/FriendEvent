//
//  User.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-15.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import Foundation
import Firebase

class User {
    
    var name: String
    var email: String
    var id: String
    var latitude: Double
    var longitude: Double
    var distance: Int
    var privateMessages: [Messages]?
    var newPrivateMessage: Bool?
    
    init(email: String, userID: String, name: String, latitude: Double = 0, longitude: Double = 0, distance: Int = 0, newPrivateMessage: Bool = false, privateMessages: [Messages]?) {
        self.email = email
        self.id = userID
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.privateMessages = privateMessages
        self.newPrivateMessage = newPrivateMessage
    }
    

    
}
