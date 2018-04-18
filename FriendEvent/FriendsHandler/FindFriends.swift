//
//  FriendList.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-15.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth


class FindFriends: UITableViewController, UISearchResultsUpdating {
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    
    /* The user Firebase reference */
    let USER_REF = Database.database().reference().child("users")
    
    /** The Firebase reference to the current user tree */
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    
    /** The current user's id */
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    
    var CURRENT_USER_FRIENDS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("friends")
    }
    var databaseRef = Database.database().reference()
    
    var userArray = [User]()
    var filtredUsers = [User]()
    var friendsIDsList = [String]()
    
    
    
    @IBOutlet var userTableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addFriendObserver()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        fetchUsers()
        self.userTableView.delegate = self
        self.userTableView.dataSource = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    

    var otherUser: NSDictionary?
    
    
    func fetchUsers(){
         Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            let email = snapshot.childSnapshot(forPath: "Email").value as! String
            let id = snapshot.key as String
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            let user = User(email: email, userID: id, name: name, privateMessages: nil)
            
            if (self.CURRENT_USER_ID != id){
                
                self.userArray.append(user)
                self.userTableView.reloadData()
            }
        }, withCancel: nil)
    }
    
    //    /** Sends a friend request to the user with the specified id */
    func sendRequestToUser(_ userID: String) {
        USER_REF.child(userID).child("requests").child(CURRENT_USER_ID).setValue(true)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != ""{
            return filtredUsers.count
        }
        else {
            return self.userArray.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user : User
        
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filtredUsers[indexPath.row]
        }
        else {
            user = self.userArray[indexPath.row]
        }
        let cell:TableCell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as! TableCell
        
        cell.button.tag = indexPath.row
        
        for friendsID in friendsIDsList{
            if user.id == friendsID{
               cell.button.isHidden = true
            }
        }
        cell.button.addTarget(self, action: #selector(pressButton(_:)), for: .touchUpInside)
        cell.nameLabel.text = user.name
        cell.mailLabel.text = user.email
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        
        
        view.backgroundColor = PURPLE_COLOR
        
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 5, width: 300, height: 35)
        label.text = "All users"
        view.addSubview(label)
        return view
    }
    
    
    @objc func pressButton(_ button: UIButton) {
        button.isHidden = true
        if searchController.isActive && searchController.searchBar.text != ""{
            sendRequestToUser(filtredUsers[button.tag].id)
            
            
        }
        else {
            sendRequestToUser(userArray[button.tag].id)
            
        }
    }
    
    func addFriendObserver() {
        CURRENT_USER_FRIENDS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.friendsIDsList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.friendsIDsList.append(id)
                self.userTableView.reloadData()
                
            }
            // If there are no children, run completion here instead
            if snapshot.childrenCount == 0 {
            }
        })
    }
    
    func filtereContent(searchText: String){
        self.filtredUsers = self.userArray.filter{ user in
            let userEmail = user.email
            return (userEmail.lowercased().contains(searchText.lowercased()))
            
        }
        userTableView.reloadData()
       
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filtereContent(searchText: self.searchController.searchBar.text!)
    }
    
}
