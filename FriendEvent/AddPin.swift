//
//  AddPin.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-05.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import MapKit

class AddPin: NSObject, MKAnnotation{
    
    var title: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinates: CLLocationCoordinate2D){
        self.title = title
        self.coordinate = coordinates
        
    }
    
    
}
