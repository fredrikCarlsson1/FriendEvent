//
//  TabBarController.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-05.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    var counter: Int?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tabItems = self.tabBar.items as NSArray!

        // In this case we want to modify the badge number of the third tab:
        let tabItem = tabItems![2] as! UITabBarItem
        
        if let friendCount = counter{
            tabItem.badgeValue = String(friendCount)
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {

    }
    
    
}
