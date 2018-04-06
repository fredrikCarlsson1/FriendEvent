//
//  ViewController.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-05.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth


class StartView: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var newEventBadge: UIImageView!
    @IBOutlet weak var newEventBadgeLabel: UILabel!
    @IBOutlet weak var newFriendBadge: UIImageView!
    @IBOutlet weak var newFriendBadgeLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var CURRENT_USER_REQUESTS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("requests")
    }
    var CURRENT_USER_EVENTS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("Events")
    }
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    let USER_REF = Database.database().reference().child("users")
    
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    var CURRENT_USER_FRIENDS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("friends")
    }
    var dbReference: DatabaseReference?
    var dbHandler: DatabaseHandle?
    
    var friendCount = 0
    var pin:AddPin?
    var friendList = [User]()
    var events = [Event]()

    override func viewDidLoad() {
        super.viewDidLoad()
        dbReference = Database.database().reference()
        
        addFriendObserver()

        mapView.delegate = self
        mapView.dropShadow()
        self.mapView.setUserTrackingMode(.follow, animated: true)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        mapView.addGestureRecognizer(gestureRecognizer)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addRequestObserver()
        eventObserver()
    }
    
    //MARK: FRIEND REQUESTS - Increases the friends badge count with one for every friend request the current user has
    func addRequestObserver() {
        self.friendCount = 0
        CURRENT_USER_REQUESTS_REF.observe(DataEventType.value, with: { (snapshot) in
            
            for _ in snapshot.children.allObjects as! [DataSnapshot] {
                self.friendCount += 1
                if self.friendCount > 0 {
                    self.newFriendBadge.isHidden = false
                    self.newFriendBadgeLabel.isHidden = false
                    self.newFriendBadgeLabel.text = String(self.friendCount)
                }
            }
        })
        if self.friendCount == 0 {
            self.newFriendBadge.isHidden = true
            self.newFriendBadgeLabel.isHidden = true
        }
    }
    
    
    //MARK: Adds a friend observer. The completion function will run every time this list changes, allowing you
    // to update your UI. Keeps the friendlist under the mapview updated
    func addFriendObserver() {
        CURRENT_USER_FRIENDS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.friendList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.getUser(id, completion: { (user) in
                    self.friendList.append(user)
                    self.tableView.reloadData()
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
            completion(User(email: email, userID: id, name: name))
        })
    }
    

    //MARK: GET ALL EVENTS (If they are unread, they get saved in the "events"-array
    func eventObserver() {
        CURRENT_USER_EVENTS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.events.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                let eventID = child.childSnapshot(forPath: "eventID").value as! String
                
                self.getEvent(eventID, completion: { (event) in
                    if child.childSnapshot(forPath: "hasBeenRead").value as! Bool == false{
                        event.eventId = id
                        event.eventReference = eventID
                        self.events.append(event)
                        if event.hasUnreadTextMessage{
                            
                        }
                        self.newEventBadgeLabel.isHidden = false
                        self.newEventBadge.isHidden = false
                        self.newEventBadgeLabel.text = String(self.events.count)
                    }
                })
            }
            if self.events.count > 0 {
                self.showAlert(title: "New invitation!", message: "You have been invited to a new event.\nCheck it out!")
            }
            
            
            if snapshot.childrenCount == 0 {
                self.newEventBadgeLabel.isHidden = true
                self.newEventBadge.isHidden = true
                
            }
        })
        
    }
    
    //Gets all events and updates badge if there is a new Guestbook message in any of the events
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
            
            for child in snapshot.childSnapshot(forPath: "invitedFriends").children {
                let snap = child as! DataSnapshot
                let key = snap.key
                let nameValue = snap.childSnapshot(forPath: "name").value as! String
                let answerValue = snap.childSnapshot(forPath: "answer").value as! String
                let invitedFriend = [key:[nameValue:answerValue]]
                
                if (self.CURRENT_USER_ID == key){
                    if snap.childSnapshot(forPath: "newTextMessage").value as! Bool == true {
                        self.newEventBadgeLabel.isHidden = false
                        self.newEventBadge.isHidden = false
                        self.newEventBadgeLabel.text = String("NYTT")
                        print("NYTT")
                    }
                    else {
                        self.newEventBadgeLabel.isHidden = true
                        self.newEventBadge.isHidden = true
                        print ("INGET NYTT")
                    }
                    invitedFriends.append(invitedFriend)
                }
            }
            completion(Event(title: title, time: time, description: description, soundRef: soundRef, imageRef: imageRef, latitude: latitude, longitude: longitude, type: type, invitedFriends: invitedFriends, host: host))
            
        })
        
    }
    
    //MARK: Shows alert when current user is invited to a new Event
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { (action) in
            self.openEvent()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func openEvent(){
        performSegue(withIdentifier: "popUpSegue", sender: self)
    }
    

    
    //MARK: ALL map functions
    @objc func handleTap(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        
        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let width = 150.0 //meter
        let height = 150.0
        let region = MKCoordinateRegionMakeWithDistance(center, width, height)
        self.mapView.setRegion(region, animated: true)
        
        //        let coordinate = CLLocationCoordinate2D(latitude: 59.3304, longitude: 18.0588)
        //
        //        pin = AddPin(title: "Spot", coordinates: coordinate)
        //        mapView.addAnnotation(pin!)
    }
    
    //    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //        let annotationView = MKAnnotationView(annotation: pin, reuseIdentifier: "myPin")
    //        let button = UIButton()
    //        annotationView.addSubview(button)
    //        annotationView.image = UIImage(named: "checkMark")
    //        let transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    //        annotationView.transform = transform
    //        return annotationView
    //    }
    //
    
    
    //MARK: ALL table view functions - (Displays friends under mapview)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = friendList[indexPath.row].name
        return cell
    }
    
    
    //
    @IBAction func newEventSegue(_ sender: UIButton) {
        performSegue(withIdentifier: "newEventSegue", sender: self)
    }
    
    //Sends data to new another viewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EventPopUP{
            destination.event = events[0]
            destination.eventID = events[0].eventId
        }
        if let destination = segue.destination as? TabBarController {
            destination.counter = friendCount
        }
    }
    
    
    
}

