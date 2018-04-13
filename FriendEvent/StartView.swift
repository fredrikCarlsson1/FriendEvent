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


class StartView: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

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
    
    var friendList = [User]()
    var events = [Event]()
  

    override func viewDidLoad() {
        super.viewDidLoad()
        dbReference = Database.database().reference()
        self.tableView.rowHeight = 60

        mapView.delegate = self
        mapView.showsUserLocation = true
      
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addFriendObserver()
        addRequestObserver()
        eventObserver()
        
        zoomInOnLocation()
        
      
    }
    
    //MARK: ALL map functions
    func getDistance(latitude: Double, longitude: Double) -> Int{
        let friendLocation = CLLocation(latitude: latitude, longitude: longitude)
        let myLocation = mapView.userLocation.coordinate
        let myLocationCoordinates = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        
        let distanceInMeters = friendLocation.distance(from: myLocationCoordinates)
        
        return Int(distanceInMeters*0.001)
        
    }
    

    
    func placeAnnotation(user: User) {

        //create annotation

        let annotation = MKPointAnnotation()
        
        annotation.title = user.name
        
        annotation.coordinate = CLLocationCoordinate2DMake(user.latitude, user.longitude)
        self.mapView.addAnnotation(annotation)
  
    }
    
    var pin:AddPin?
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKUserLocation) {
            
            let annotationView = MKAnnotationView(annotation: pin, reuseIdentifier: "myPin")
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
                annotationView.canShowCallout = true
                annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView.canShowCallout = true
                annotationView.annotation = annotation
            }
            
            
            
            annotationView.image = UIImage(named: "user")
            annotationView.clipsToBounds = false
            annotationView.layer.shadowColor = UIColor.lightGray.cgColor
            annotationView.layer.shadowOpacity = 1
            annotationView.layer.shadowOffset = CGSize.zero
            annotationView.layer.shadowRadius = 10
            annotationView.layer.shadowPath = UIBezierPath(roundedRect: annotationView.bounds, cornerRadius: 10).cgPath
          
            let transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            annotationView.transform = transform
            return annotationView
        }
        else {
            return nil
        }
    }
 
    
    
   func zoomInOnLocation() {

        //get location
        let location = mapView.userLocation.coordinate
        let latitude = location.latitude
        let longitude = location.longitude
      
        //Zooming in on annotation
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let span = MKCoordinateSpanMake(0.2, 0.2)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.mapView.setRegion(region, animated: true)
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
                    self.friendList.sort(by: {$1.distance > $0.distance})
                    self.placeAnnotation(user: user)
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
            let latitude = snapshot.childSnapshot(forPath: "latitude").value as! Double
            let longitude = snapshot.childSnapshot(forPath: "longitude").value as! Double
            let distance = self.getDistance(latitude: latitude, longitude: longitude)
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            completion(User(email: email, userID: id, name: name, latitude: latitude, longitude: longitude, distance: distance))
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
                        if self.showingAlert == false{
                        self.showAlert(title: "New invite!", message: "You got invited to a new event! \nCheck it out!")
                        }
                        if event.hasUnreadTextMessage{
                            
                        }
                        self.newEventBadgeLabel.isHidden = false
                        self.newEventBadge.isHidden = false
                        self.newEventBadgeLabel.text = String(self.events.count)
                        
                    }
                })

            }
      
            if snapshot.childrenCount == 0 {
                self.newEventBadgeLabel.isHidden = true
                self.newEventBadge.isHidden = true
            }
        })
        
    }
    
    var showingAlert = false
    
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
                        
                    }
                    else {
                        self.newEventBadgeLabel.isHidden = true
                        self.newEventBadge.isHidden = true
                        
                    }
                    invitedFriends.append(invitedFriend)
                }
            }
            completion(Event(title: title, time: time, description: description, soundRef: soundRef, imageRef: imageRef, latitude: latitude, longitude: longitude, type: type, invitedFriends: invitedFriends, host: host))
            
        })
        
    }
    
    //MARK: Shows alert when current user is invited to a new Event
    func showAlert(title: String, message: String){
        self.showingAlert = true
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
    

    
    
    
    //MARK: ALL table view functions - (Displays friends under mapview)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "startViewCell", for: indexPath) as! StartViewCells
        let user = friendList[indexPath.row]
        
        cell.nameLabel.text = user.name
        cell.emailLabel.text = user.email
        if (user.longitude != 0 && user.latitude != 0){
        cell.distanceLabel.text = "\(user.distance) km"
        }
        else {
            cell.distanceLabel.text = "-"
        }
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

