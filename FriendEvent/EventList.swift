//
//  EventList.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-09.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import Firebase

class EventList: UITableViewController {
    
    var eventList = [Event]()
    
    @IBOutlet var eventTableView: UITableView!
    /* The user Firebase reference */
    let USER_REF = Database.database().reference().child("users")
    
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    
    var CURRENT_USER_EVENTS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("Events")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        eventObserver()
        
    }

    
    func eventObserver() {
        CURRENT_USER_EVENTS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.eventList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.getEvent(id, completion: { (event) in
                    self.eventList.append(event)
                    self.eventTableView.reloadData()
                })
        
            }
           
            if snapshot.childrenCount == 0 {
                self.eventTableView.reloadData()
            }
        })
    }
    
    func getEvent(_ eventID: String, completion: @escaping (Event) -> Void) {
        CURRENT_USER_REF.child("Events").child(eventID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let title = snapshot.childSnapshot(forPath: "title").value as! String
            print(title)
            let time = snapshot.childSnapshot(forPath: "time").value as! String
            print(time)
            let description = snapshot.childSnapshot(forPath: "description").value as! String
            let imageRef = snapshot.childSnapshot(forPath: "imageRef").value as! String
            let soundRef = snapshot.childSnapshot(forPath: "soundRef").value as! String
            
            completion(Event(title: title, time: time, description: description, soundRef: soundRef, imageRef: imageRef))
        })
    }
    
    
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return eventList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: EventListCell = tableView.dequeueReusableCell(withIdentifier: "eventListCell", for: indexPath) as! EventListCell
        
        cell.eventTitle.text = eventList[indexPath.row].title
        cell.eventTime.text = eventList[indexPath.row].time
        
        return cell
    }

    

}
