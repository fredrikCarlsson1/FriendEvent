//
//  FriendRequests.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-15.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class FriendRequests: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var requestList = [User]()
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    @IBOutlet weak var tableView: UITableView!
    
    /* The user Firebase reference */
    let USER_REF = Database.database().reference().child("users")
    
    /** The Firebase reference to the current user tree */
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    
    /** The Firebase reference to the current user's friend request tree */
    var CURRENT_USER_REQUESTS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("requests")
    }
    /** The current user's id */
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRequestObserver()
    }
    
    /** Gets the User object for the specified user id */
    func getUser(_ userID: String, completion: @escaping (User) -> Void) {
        USER_REF.child(userID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let email = snapshot.childSnapshot(forPath: "Email").value as! String
            let id = snapshot.key
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            completion(User(email: email, userID: id, name: name, privateMessages: nil))
        })
    }
    
    func addRequestObserver() {
        CURRENT_USER_REQUESTS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.requestList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key

                self.getUser(id, completion: { (user) in
                    self.requestList.append(user)
                    self.tabBarItem.badgeValue = String(self.requestList.count)
                    self.tableView.reloadData()
                })
            }
            // If there are no children, run completion here instead
            if snapshot.childrenCount == 0 {
                self.tabBarItem.badgeValue = nil
                self.tableView.reloadData()
            }
        })
    }
    
    // Accepts a friend request from the user with the specified id
    @objc func acceptFriendRequest(_ userID: String) {
        CURRENT_USER_REF.child("requests").child(userID).removeValue()
        CURRENT_USER_REF.child("friends").child(userID).child("messages").setValue(true)
        CURRENT_USER_REF.child("friends").child(userID).child("newMessage").setValue(false)
        USER_REF.child(userID).child("friends").child(CURRENT_USER_ID).child("newMessage").setValue(false)
        USER_REF.child(userID).child("friends").child(CURRENT_USER_ID).child("messages").setValue(true)
        USER_REF.child(userID).child("requests").child(CURRENT_USER_ID).removeValue()


    }
    
    /** Decline a friend request from the user with the specified id */
    func declineFriendRequest(_ userID: String) {
        CURRENT_USER_REF.child("requests").child(userID).removeValue()

       // USER_REF.child(userID).child("requests").child(CURRENT_USER_ID).removeValue()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestList.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:FriendRequestTableCell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath) as! FriendRequestTableCell
        
        cell.acceptFriendButton.tag = indexPath.row
        
        cell.acceptFriendButton.addTarget(self, action: #selector(acceptButton(_:)), for: .touchUpInside)
        
        cell.rejectFriendButton.addTarget(self, action: #selector(rejectButton(_:)), for: .touchUpInside)
        
        
        cell.nameLabel.text = requestList[indexPath.row].name
        cell.emailLabel.text = requestList[indexPath.row].email
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

     func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()


        view.backgroundColor = PURPLE_COLOR

        let label = UILabel()
        label.frame = CGRect(x: 20, y: 5, width: 300, height: 35)
        label.text = "My friend requests"
        view.addSubview(label)
        return view
    }
 
    @objc func acceptButton(_ button: UIButton) {
        print(button.tag);
        acceptFriendRequest(requestList[button.tag].id)
    }
    
    @objc func rejectButton(_ button: UIButton) {
        declineFriendRequest(requestList[button.tag].id)
    }
    
    
    
    
}














