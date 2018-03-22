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
    var databaseRef = Database.database().reference()
    
    var userArray = [User]()
    var filtredUsers = [User]()
    
    
    
    @IBOutlet var userTableView: UITableView!
    let searchController = UISearchController(searchResultsController: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            let email = snapshot.childSnapshot(forPath: "Email")
            let id = snapshot.key as String
            
            let user = User(email: (email.value as? String)!, userID: id)
            self.userArray.append(user)
            
            self.userTableView.reloadData()
            
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
        
        cell.button.addTarget(self, action: #selector(pressButton(_:)), for: .touchUpInside)
        cell.textLabel?.text = user.email
        
        return cell
    }
    
    @objc func pressButton(_ button: UIButton) {
        if searchController.isActive && searchController.searchBar.text != ""{
            sendRequestToUser(filtredUsers[button.tag].id)
            print (filtredUsers[button.tag].id)
        }
        else {
            sendRequestToUser(userArray[button.tag].id)
            print (userArray[button.tag].id)
        }
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
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
