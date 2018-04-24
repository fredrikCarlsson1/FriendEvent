//
//  MyFriends.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-16.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import MapKit


class MyFriends: UITableViewController, CLLocationManagerDelegate {
    @IBOutlet var friendsTableView: UITableView!
    
    let USER_REF = Database.database().reference().child("users")
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    var CURRENT_USER_FRIENDS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("friends")
    }
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    var friendLists = [User]()
    var myLongitude: Double = 0
    var myLatitude: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getMyLocation()
        self.tableView.rowHeight = 60
        addFriendObserver()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendLists.count
    }
    
    /** Unfriends the user with the specified id */
    func removeFriend(_ userID: String) {
        CURRENT_USER_REF.child("friends").child(userID).removeValue()
        USER_REF.child(userID).child("friends").child(CURRENT_USER_ID).removeValue()
    }
    
    
    //MARK: Adds a friend observer. The completion function will run every time this list changes, allowing you
    // to update your UI. Keeps the friendlist under the mapview updated
    func getMyLocation(){
        CURRENT_USER_REF.observe(DataEventType.value, with: { (snapshot) in
            
            let id = snapshot.key
            self.getUser(id, completion: { (user) in
                
                self.myLongitude = user.longitude
                self.myLatitude = user.latitude
                print(self.myLongitude)
                print(self.myLatitude)
                
            })
            
            // If there are no children, run completion here instead
            if snapshot.childrenCount == 0 {
            }
        })
        
    }
    
    func addFriendObserver() {
        CURRENT_USER_FRIENDS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.friendLists.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.getUser(id, completion: { (user) in
                    self.friendLists.append(user)
                    
                    self.friendLists.sort(by: {$1.distance > $0.distance})
                    
                    self.friendsTableView.reloadData()
                    
                })
            }
            // If there are no children, run completion here instead
            if snapshot.childrenCount == 0 {
                
            }
        })
    }
    
    //MARK: GET USER -  Gets the User object for the specified user id
    func getUser(_ userID: String, completion: @escaping (User) -> Void) {
        USER_REF.child(userID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let email = snapshot.childSnapshot(forPath: "Email").value as! String
            let id = snapshot.key
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            let latitude = snapshot.childSnapshot(forPath: "latitude").value as! Double
            let longitude = snapshot.childSnapshot(forPath: "longitude").value as! Double
            let distance = self.getDistance(latitude: latitude, longitude: longitude)
            
            completion(User(email: email, userID: id, name: name, latitude: latitude, longitude: longitude, distance: distance, privateMessages: nil))
        })
    }
    
    func getDistance(latitude: Double, longitude: Double) -> Int{
        let friendLocation = CLLocation(latitude: latitude, longitude: longitude)
        if myLongitude != 0 && myLatitude != 0{
            let myLocation = CLLocation(latitude: self.myLatitude, longitude: self.myLongitude)
            
            let distanceInMeters = friendLocation.distance(from: myLocation)
            
            print(myLocation)
            return Int(distanceInMeters*0.001)
        }
        else {
            return 0
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendListCells", for: indexPath) as! FriendListCell
        
        cell.nameLabel.text = friendLists[indexPath.row].name
        cell.emailLabel.text = friendLists[indexPath.row].email
        if (friendLists[indexPath.row].longitude != 0 && friendLists[indexPath.row].latitude != 0) {
            cell.distanceLabel.text =  String(friendLists[indexPath.row].distance)
        }
        else {
            cell.distanceLabel.text = "-"
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")
            self.removeFriend(self.friendLists[indexPath.row].id)
            
            self.friendLists.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        
        
        view.backgroundColor = PURPLE_COLOR
        
        let label = UILabel()
        
        label.frame = CGRect(x: 40, y: 5, width: 300, height: 35)
        label.text = "My friends"
        view.addSubview(label)
        return view
    }
    
    
    
}
