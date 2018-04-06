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
    let latitude: Double
    let longitude: Double
    let type: String
    let imageRef: String?
    let soundRef: String?
    var eventId: String?
    var eventReference: String?
    var invitedFriends: [[String:[String:String]]]
    let host: String
    var hasUnreadTextMessage: Bool
    var hasBeenRead: Bool?
    
    
    init(title: String, time: String, description: String?, soundRef: String?, imageRef: String?, latitude: Double, longitude: Double, type: String, invitedFriends: [[String:[String:String]]], host: String, newTextMessage: Bool = false){
        self.title = title
        self.time = time
        self.description = description
        self.soundRef = soundRef
        self.imageRef = imageRef
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.invitedFriends = invitedFriends
        self.host = host
        self.hasUnreadTextMessage = newTextMessage
    }
    
    
    
}
