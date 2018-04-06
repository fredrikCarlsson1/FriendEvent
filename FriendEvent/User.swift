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
    
    init(email: String, userID: String, name: String) {
        self.email = email
        self.id = userID
        self.name = name 
    }
}
