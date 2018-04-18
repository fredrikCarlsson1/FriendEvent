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

class StartView: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var newEventBadge: UIImageView!
    @IBOutlet weak var newEventBadgeLabel: UILabel!
    @IBOutlet weak var newFriendBadge: UIImageView!
    @IBOutlet weak var newFriendBadgeLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newGuestbookView: UIImageView!
    @IBOutlet weak var newGuestbookLabel: UILabel!
    @IBOutlet weak var sendMessageTextField: UITextField!
    @IBOutlet weak var privateMessageCollectionView: UICollectionView!
    @IBOutlet weak var privateMessageView: UIView!
    @IBOutlet weak var closePrivateMessageOutlet: UIButton!
    
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    
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
    
    var CURRENT_USERNAME: String?
    
    func setCurrentUserName (){
        CURRENT_USER_REF.observeSingleEvent(of: .value) { (snapshot) in
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            self.CURRENT_USERNAME = name
        }
    }
    
    var friendCount = 0
    var friendList = [User]()
    var events = [Event]()
    var pin:AddPin?
    var showingAlert = false
    var selectedFriend: User?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 60
        setCurrentUserName()
        mapView.delegate = self
        mapView.showsUserLocation = true
        privateMessageCollectionView.alwaysBounceVertical = true
        privateMessageCollectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addRequestObserver()
        eventObserver()
        zoomInOnLocation()
        addFriendObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.newGuestbookLabel.isHidden = true
        self.newGuestbookView.isHidden = true
        self.newEventBadge.isHidden = true
        self.newEventBadgeLabel.isHidden = true
    }
    
    func removeUserObserver() {
        USER_REF.removeAllObservers()
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
            annotationView.layer.shadowOpacity = 0.4
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
    
    func zoomInOnFriendsLocation(latitude: Double, longitude: Double){
        //Zooming in on annotation
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let span = MKCoordinateSpanMake(0.01, 0.01)
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
    
    
    //MARK: FRIENDS - Adds a friend observer. The completion function will run every time this list changes, allowing you
    // to update your UI. Keeps the friendlist under the mapview updated
    func addFriendObserver() {
        print("addFriendOBSERVER")
        CURRENT_USER_FRIENDS_REF.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            self.friendList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                var newMessages = false
                if let newMessage = snapshot.childSnapshot(forPath: id).childSnapshot(forPath: "newMessage").value as? Bool{
                    newMessages = newMessage
                }
                self.getUser(id, completion: { (user) in
                    user.newPrivateMessage = newMessages
                    self.friendList.append(user)
                    self.friendList.sort(by: {$1.distance > $0.distance})
                    self.placeAnnotation(user: user)
                    self.tableView.reloadData()
                    self.privateMessageCollectionView.reloadData()
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
            let messageArray = [Messages]()

            completion(User(email: email, userID: id, name: name, latitude: latitude, longitude: longitude, distance: distance, privateMessages: messageArray))
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
                        self.newGuestbookView.isHidden = false
                        self.newGuestbookLabel.isHidden = false
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
    
    //Segues to the event in alertViewn
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
        cell.sendPrivateMessageButton.tag = indexPath.row
        
        cell.nameLabel.text = user.name
        cell.emailLabel.text = user.email
        cell.sendPrivateMessageButton.isHidden = true
        if (user.longitude != 0 && user.latitude != 0){
            cell.distanceLabel.text = "\(user.distance) km"
        }
        else {
            cell.distanceLabel.text = "-"
        }
        if (user.newPrivateMessage == true){
            cell.sendPrivateMessageButton.isHidden = false
            cell.sendPrivateMessageButton.setImage(#imageLiteral(resourceName: "newPrivateMessage"), for: .normal)
        }
        else{
            cell.sendPrivateMessageButton.isHidden = true
            cell.sendPrivateMessageButton.setImage(#imageLiteral(resourceName: "sendPrivateMessage"), for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        zoomInOnFriendsLocation(latitude: friendList[indexPath.row].latitude, longitude: friendList[indexPath.row].longitude)
        self.tableView.reloadData()
        self.selectedFriend = friendList[indexPath.row]
        self.privateMessageCollectionView.reloadData()
        if let cell = tableView.cellForRow(at: indexPath) as? StartViewCells {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
                cell.sendPrivateMessageButton.isHidden = false
            }, completion: nil)
            
        }
    }

    //Go to all eventlist
    @IBAction func newEventSegue(_ sender: UIButton) {
        performSegue(withIdentifier: "newEventSegue", sender: self)
    }
    
    //Sends data to new View controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EventPopUP{
            destination.event = events[0]
            destination.eventID = events[0].eventId
        }
        if let destination = segue.destination as? TabBarController {
            destination.counter = friendCount
        }
    }
    
    //MARK: Send private messages
    func sendMessage(){
        
        let ref = CURRENT_USER_REF.child("friends").child(self.selectedFriend!.id).child("messages")
        let friendsRef = Database.database().reference().child("users").child(self.selectedFriend!.id).child("friends").child(CURRENT_USER_ID).child("messages")
        let newFriendMessageRef = Database.database().reference().child("users").child(self.selectedFriend!.id).child("friends").child(CURRENT_USER_ID)
        let autoRef = ref.childByAutoId()
        let autoFriendRef = friendsRef.childByAutoId()
        if sendMessageTextField.text != "" {
            let value = ["text": sendMessageTextField.text!, "from": String(CURRENT_USER_ID), "timeStamp": Int(Date.timeIntervalSinceReferenceDate)] as [String: Any]
            let newMessageValue = ["newMessage": true] as [String: Bool]
            autoFriendRef.updateChildValues(value)
            newFriendMessageRef.updateChildValues(newMessageValue)
            autoRef.updateChildValues(value)
            self.sendMessageTextField.text = ""
        }
    }
    
    @IBAction func sendPrivateMessageButton(_ sender: UIButton) {
        sendMessage()
        self.privateMessageCollectionView.reloadData()
        
    }
    
    @IBAction func showPrivateMessageView(_ sender: UIButton) {
        self.selectedFriend = self.friendList[sender.tag]
        self.observePrivateMessages()
        let ref = CURRENT_USER_REF.child("friends").child(self.selectedFriend!.id)
        let newMessageValue = ["newMessage": false] as [String: Bool]
        ref.updateChildValues(newMessageValue)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.privateMessageView.alpha = 1
        }, completion: nil)
        self.closePrivateMessageOutlet.isHidden = false
    }
    
    @IBAction func closePrivateMessageButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.privateMessageView.alpha = 0
        }, completion: nil)
        self.closePrivateMessageOutlet.isHidden = true
    }
    
    func observePrivateMessages() {
        let commentsRef = CURRENT_USER_REF.child("friends").child((selectedFriend?.id)!).child("messages")
        self.selectedFriend?.privateMessages!.removeAll()
        commentsRef.observe(.childAdded, with: { (snapshot) -> Void in
            let text = snapshot.childSnapshot(forPath: "text").value as! String
            let time = snapshot.childSnapshot(forPath: "timeStamp").value as! Int
            let from = snapshot.childSnapshot(forPath: "from").value as! String
            let newMessage = Messages(id: from, message: text, timeStamp: time)
            self.selectedFriend?.privateMessages!.append(newMessage)
            self.privateMessageCollectionView.reloadData()
            let lastItemIndex = IndexPath(item: (self.selectedFriend?.privateMessages!.count)!-1, section: 0)
            self.privateMessageCollectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: false)
            self.tableView.reloadData()
        })
    }
    
    //MARK: COLLECTIONVIEWS
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let selectedFriendCount = self.selectedFriend?.privateMessages?.count{
            return selectedFriendCount
        }
        else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCell", for: indexPath) as! MessageCell
        cell.textView.text = self.selectedFriend?.privateMessages![indexPath.row].message
        
        if self.selectedFriend?.privateMessages![indexPath.row].ID == CURRENT_USER_ID {
            cell.bubbleView.backgroundColor = PURPLE_COLOR
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.blueTopAnchor?.isActive = true
            cell.greyTopAnchor?.isActive = false
            cell.userLabelLeftAnchor?.isActive = false
            cell.userLabelRightAnchor?.isActive = true
            cell.userLabel.isHidden = false
            if let username = CURRENT_USERNAME {
                cell.userLabel.text = username
            } else {
                cell.userLabel.text = "Me"
            }
            cell.userLabel.textAlignment = .right
        }
        else {
            cell.bubbleView.backgroundColor = UIColor.lightGray
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.blueTopAnchor?.isActive = false
            cell.greyTopAnchor?.isActive = true
            cell.userLabel.isHidden = false
            cell.userLabelLeftAnchor?.isActive = true
            cell.userLabelRightAnchor?.isActive = false
            cell.userLabel.textAlignment = .left
            cell.userLabel.text = self.selectedFriend?.name
        }
        
        cell.bubbleWidthAnchor?.constant = estimatedHeightForText(text: (self.selectedFriend?.privateMessages![indexPath.row].message)!).width + 32
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        height = estimatedHeightForText(text: (self.selectedFriend?.privateMessages![indexPath.item].message)!).height + 40
        
        return CGSize(width: privateMessageCollectionView.frame.width, height: height)
    }
    
    private func estimatedHeightForText(text: String)-> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)], context: nil)
    }
    
    
}








