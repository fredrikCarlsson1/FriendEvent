//
//  Profile.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-09.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import CoreLocation

class Profile: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource{
    
    
    

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emailCell", for: indexPath)
            
            return cell
        }
        else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath)
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "passwordCell", for: indexPath)
            return cell
        }
    }
    

    

 

    
}
