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
    
    var eventID: String?
    
    @IBOutlet var eventTableView: UITableView!
    /* The user Firebase reference */
    let USER_REF = Database.database().reference().child("users")
    
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    
    var CURRENT_USER_EVENTS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("Events")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eventObserver()
    }
    
    
    func eventObserver() {
        CURRENT_USER_EVENTS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.eventList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                let eventID = child.childSnapshot(forPath: "eventID").value as! String
                let hasBeenRead =  child.childSnapshot(forPath: "hasBeenRead").value as! Bool
                
                self.getEvent(eventID, completion: { (event) in
                    event.eventId = id
                    event.eventReference = eventID
                    event.hasBeenRead = hasBeenRead
                    self.eventList.append(event)
                    self.eventList.sort(by: {$1.time > $0.time})
                    self.eventTableView.reloadData()
                })
            }
            
            if snapshot.childrenCount == 0 {
                self.eventTableView.reloadData()
            }
        })
        
    }
    
    func getEvent(_ eventID: String, completion: @escaping (Event) -> Void) {
        Database.database().reference().child("Events").child(eventID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let title = snapshot.childSnapshot(forPath: "title").value as! String
            let time = snapshot.childSnapshot(forPath: "time").value as! String
            let description = snapshot.childSnapshot(forPath: "description").value as! String
            let imageRef = snapshot.childSnapshot(forPath: "imageRef").value as! String
            let soundRef = snapshot.childSnapshot(forPath: "soundRef").value as! String
            let latitude = snapshot.childSnapshot(forPath: "position").childSnapshot(forPath: "latitude").value as! Double
            let longitude = snapshot.childSnapshot(forPath: "position").childSnapshot(forPath: "longitude").value as! Double
            let type =  snapshot.childSnapshot(forPath: "eventType").value as! String
            let host = snapshot.childSnapshot(forPath: "host").value as! String
            var invitedFriends = [[String:[String:String]]]()
            var newTextMessage = Bool()
            for child in snapshot.childSnapshot(forPath: "invitedFriends").children {
                let snap = child as! DataSnapshot
                let key = snap.key
                let nameValue = snap.childSnapshot(forPath: "name").value as! String
                let answerValue = snap.childSnapshot(forPath: "answer").value as! String
                let invitedFriend = [key:[nameValue:answerValue]]
                
                if key == self.CURRENT_USER_ID {
                    newTextMessage = snap.childSnapshot(forPath: "newTextMessage").value as! Bool
                }
                invitedFriends.append(invitedFriend)
            }
            
            
            completion(Event(title: title, time: time, description: description, soundRef: soundRef, imageRef: imageRef, latitude: latitude, longitude: longitude, type: type, invitedFriends: invitedFriends, host: host, newTextMessage: newTextMessage))
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
        
        let event = eventList[indexPath.row]
        
        if event.hasBeenRead == false{
            cell.eventTitle.font = UIFont.boldSystemFont(ofSize: 16)
        }
        if event.hasUnreadTextMessage == true {
            cell.badgeView.isHidden = false
            cell.badgeLabel.text = "+1"
        }
        
        let index = eventList[indexPath.row].time.index(of: "&")!
        let dateStr = eventList[indexPath.row].time[..<index]
        let index2 = eventList[indexPath.row].time.index(index, offsetBy: 1)
        let timeStr = eventList[indexPath.row].time[index2...]
        
        
        
        cell.eventTitle.text = eventList[indexPath.row].title
        cell.eventDate.text = String(dateStr)
        cell.eventTime.text = String(timeStr)
        cell.eventTypeImage.layer.masksToBounds = false
        cell.eventTypeImage.layer.cornerRadius = 20
        cell.eventTypeImage.clipsToBounds = true
        
        
        switch eventList[indexPath.row].type {
        case "Öl":
            cell.eventTypeImage.image = UIImage(named: "beer_small")
        default:
            cell.eventTypeImage.image = UIImage(named: "question-mark_small")
        }
        
        
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "eventListToPopUp", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EventPopUP {
            if let indexPath = tableView.indexPathForSelectedRow{
                let selectedRow = indexPath.row
                destination.event = eventList[selectedRow]
                
                if let id = eventList[selectedRow].eventId{
                    destination.eventID = id
                    
                }
            }
            
            
        }
    }
    
    
    
}
