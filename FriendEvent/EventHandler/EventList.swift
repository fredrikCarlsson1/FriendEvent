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
    struct AllEvents {
        let title: String!
        var events: [Event]!
    }
    var allEventsArray = [AllEvents]()
    
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    var eventID: String?
    
    @IBOutlet var eventTableView: UITableView!

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
    var newEvents = [Event]()
    var oldEvents = [Event]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 70
        allEventsArray = [AllEvents(title: "Upcoming events", events: newEvents), AllEvents(title: "Previous events", events: oldEvents)]
       // observeNewGuestbookMessages()
        eventObserver()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.eventTableView.reloadData()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeUserObserver()
    }
    func removeUserObserver() {
        USER_REF.removeAllObservers()
    }
    
    var handle: UInt = 0
    var eventRef: DatabaseReference {
        return CURRENT_USER_EVENTS_REF
    }
    
    
    func eventObserver() {
        print("Event observer from EVENTLIST!")
        handle = eventRef.observe(DataEventType.value, with: { (snapshot) in
            self.allEventsArray[1].events.removeAll()
            self.allEventsArray[0].events.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                let eventID = child.childSnapshot(forPath: "eventID").value as! String
                let hasBeenRead =  child.childSnapshot(forPath: "hasBeenRead").value as! Bool
                
                let timeStamp = child.childSnapshot(forPath: "timeStamp").value as! Int
                
                self.getEvent(eventID, completion: { (event) in
                    event.eventId = id
                    event.eventReference = eventID
                    event.hasBeenRead = hasBeenRead
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = DateFormatter.Style.short
                    
                    
                    if (self.checkDate(eventDate: timeStamp)){
                        self.allEventsArray[0].events.append(event)
                    }
                    else {
                        self.allEventsArray[1].events.append(event)
                        self.allEventsArray[1].events.sort(by: {$1.time > $0.time})
                    }
                    self.eventTableView.reloadData()
                })
            }
            
            if snapshot.childrenCount == 0 {
                self.eventTableView.reloadData()
            }
        })
        
//        eventRef.removeObserver(withHandle: handle)
//        print("event observer removed")
//        newEventObserver()
        
    }
    
    
    func newEventObserver() {
        handle = eventRef.observe(DataEventType.childAdded, with: { (snapshot) in
            self.allEventsArray[1].events.removeAll()
            self.allEventsArray[0].events.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                let eventID = child.childSnapshot(forPath: "eventID").value as! String
                let hasBeenRead =  child.childSnapshot(forPath: "hasBeenRead").value as! Bool
                
                let timeStamp = child.childSnapshot(forPath: "timeStamp").value as! Int
                
                self.getEvent(eventID, completion: { (event) in
                    event.eventId = id
                    event.eventReference = eventID
                    event.hasBeenRead = hasBeenRead
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = DateFormatter.Style.short
                    
                    
                    if (self.checkDate(eventDate: timeStamp)){
                        self.allEventsArray[0].events.append(event)
                    }
                    else {
                        self.allEventsArray[1].events.append(event)
                        self.allEventsArray[1].events.sort(by: {$1.time > $0.time})
                    }
                    self.eventTableView.reloadData()
                })
            }
            
            if snapshot.childrenCount == 0 {
                self.eventTableView.reloadData()
            }
        })
        
        eventRef.removeObserver(withHandle: handle)
        print("CHILD ADDED")
        //observeNewGuestbookMessages()
        
    }
    
    
    func checkDate(eventDate: Int)->Bool{
        let todaysTime = Int(Date().timeIntervalSince1970)
        
        if (eventDate>todaysTime){
            return true
        }
        else{
            return false
        }
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
    
    
  //MARK: TABLEVIEW Functions
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allEventsArray.count
        
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allEventsArray[section].events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: EventListCell = tableView.dequeueReusableCell(withIdentifier: "eventListCell", for: indexPath) as! EventListCell
        
        let event = allEventsArray[indexPath.section].events[indexPath.row]
        
        if event.hasBeenRead == false{
            cell.eventTitle.font = UIFont.boldSystemFont(ofSize: 16)
        }
        if event.hasUnreadTextMessage == true {
            cell.badgeView.isHidden = false
            cell.badgeLabel.text = "+1"
        }
        else {
            cell.badgeView.isHidden = true
           
        }
        
        let index = allEventsArray[indexPath.section].events[indexPath.row].time.index(of: "&")!
        let dateStr = allEventsArray[indexPath.section].events[indexPath.row].time[..<index]
        let index2 = allEventsArray[indexPath.section].events[indexPath.row].time.index(index, offsetBy: 1)
        let timeStr = allEventsArray[indexPath.section].events[indexPath.row].time[index2...]
        
        cell.eventTitle.text = allEventsArray[indexPath.section].events[indexPath.row].title
        cell.eventDate.text = String(dateStr)
        cell.eventTime.text = String(timeStr)
        cell.eventTypeImage.layer.masksToBounds = false
        cell.eventTypeImage.layer.cornerRadius = 25
        cell.eventTypeImage.clipsToBounds = true
        
        switch allEventsArray[indexPath.section].events[indexPath.row].type {
        case "Öl":
            cell.eventTypeImage.image = UIImage(named: "beer_small")
        case "Middag":
            cell.eventTypeImage.image = UIImage(named: "dinner_small")
        case "Vin":
            cell.eventTypeImage.image = UIImage(named: "wine-small")
        case "Fotboll":
            cell.eventTypeImage.image = UIImage(named: "football_small")
        case "Kaffe":
            cell.eventTypeImage.image = UIImage(named: "coffe_small")
        case "TV-spel":
            cell.eventTypeImage.image = UIImage(named: "video-game_small")
        case "Gymma":
            cell.eventTypeImage.image = UIImage(named: "gym-large")
        case "Plugga":
            cell.eventTypeImage.image = UIImage(named: "study-large")
        case "Party":
            cell.eventTypeImage.image = UIImage(named: "party-small")
        case "Konsert":
            cell.eventTypeImage.image = UIImage(named: "consert-small")
        case "Promenad":
            cell.eventTypeImage.image = UIImage(named: "walk-small")
        case "Drink":
            cell.eventTypeImage.image = UIImage(named: "drinks-small")
        case "Träna":
            cell.eventTypeImage.image = UIImage(named: "work-out-small")
        case "Spela spel":
            cell.eventTypeImage.image = UIImage(named: "board-game-small")
        case "Resa":
            cell.eventTypeImage.image = UIImage(named: "travel-small")
        case "Film":
            cell.eventTypeImage.image = UIImage(named: "watch-movie-small")
            
        default:
            cell.eventTypeImage.image = UIImage(named: "question-mark_small")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = IndexPath(row: indexPath.row, section: indexPath.section)
        let cell = tableView.cellForRow(at: indexPath) as! EventListCell
        cell.badgeView.isHidden = true
        cell.badgeLabel.isHidden = true

        performSegue(withIdentifier: "eventListToPopUp", sender: self)

    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = PURPLE_COLOR
        
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 5, width: 300, height: 35)
        label.text = allEventsArray[section].title
        view.addSubview(label)
        return view
    }
    

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")
            
            if let eventID = self.allEventsArray[indexPath.section].events[indexPath.row].eventId {
                print(eventID)
                
                self.removeEvent(eventID)
            }
            self.allEventsArray[indexPath.section].events.remove(at: indexPath.row)
            
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
//    //MARK: NEW GUESTBOOK OBSERVER
//    func observeNewGuestbookMessages() {
//        let guestbookRef = Database.database().reference().child("Events")
//        guestbookRef.observe(.childChanged, with: { (snapshot) -> Void in
//            let id = snapshot.key
//            let newMessage = snapshot.childSnapshot(forPath: "invitedFriends").childSnapshot(forPath: String(self.CURRENT_USER_ID)).childSnapshot(forPath: "newTextMessage").value as! Bool
//            for events in self.allEventsArray{
//                for event in events.events{
//                    if(event.eventReference == id){
//                        print("NEW MESSAGE UPDATE")
//                        event.hasUnreadTextMessage = newMessage
//                        self.tableView.reloadData()
//
//                    }
//                }
//            }

//            print("NEW GUESTBOOK: \(newMessage), \(id)")
//                if (id == self.CURRENT_USER_ID) {
//                    print("NEW GUESTBOOK: \(newMessage)")
//                    self.tableView.reloadData()
//                }
//        })
//    }
    
    
    
    func removeEvent(_ eventID: String) {
        CURRENT_USER_REF.child("Events").child(eventID).removeValue()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EventPopUP {
            if let indexPath = tableView.indexPathForSelectedRow{
                let selectedRow = indexPath.row
                destination.event = allEventsArray[indexPath.section].events[selectedRow]
                
                if let id = allEventsArray[indexPath.section].events[selectedRow].eventId{
                    destination.eventID = id
                }
            }
        }
    }
    
    
    
  
}









