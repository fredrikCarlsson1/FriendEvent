//
//  Event.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-25.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import Foundation

class Event {
    let title: String
    let description: String?
    let time: String
    //let place: String
    let imageRef: String?
    let soundRef: String?
    //let participants: [User]?
    
    init(title: String, time: String, description: String?, soundRef: String?, imageRef: String? ){
        self.title = title
        self.time = time
       // self.place = place
        self.description = description
        self.soundRef = soundRef
        self.imageRef = imageRef
        
    }
    
    
    
}
