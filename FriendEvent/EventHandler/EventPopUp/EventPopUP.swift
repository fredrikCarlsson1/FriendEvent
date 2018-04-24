//
//  EventPopUP.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-25.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import AVFoundation
import Alamofire

class EventPopUP: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    var currentUserAnswer = "TBA"
    var currentUserName = "No-name"
    var player: AVAudioPlayer?
    
    @IBOutlet weak var closeListenViewButtonOutlet: UIButtonX!
    @IBOutlet weak var micView: UIViewX!
    @IBOutlet weak var newTextLabel: UILabel!
    @IBOutlet weak var newTextBadge: UIImageView!
    @IBOutlet weak var guestbookCollectionView: UICollectionView!
    @IBOutlet weak var sendMessageTextField: UITextFieldX!
    @IBOutlet weak var invitationViewButtonOutlet: UIButton!
    @IBOutlet weak var guestBookViewButtonOutlet: UIButton!
    @IBOutlet weak var eventImage: UIImageViewX!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var eventDescription: UITextView!
    @IBOutlet weak var invitedFriendsCollectionView: UICollectionView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var drawButtonView: UIView!
    @IBOutlet weak var micButtonView: UIView!
    @IBOutlet weak var downloadedImageVIew: UIViewX!
    @IBOutlet weak var downloadedImage: UIImageView!
    @IBOutlet weak var guestBookView: UIView!
    @IBOutlet weak var popUpView: UIViewX!
    @IBOutlet weak var acceptButtonOutlet: UIButton!
    @IBOutlet weak var declineButtonOutlet: UIButton!
    
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    
    var CURRENT_USERNAME: String?
    
    func setCurrentUserName (){
        CURRENT_USER_REF.observeSingleEvent(of: .value) { (snapshot) in
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            self.CURRENT_USERNAME = name
        }
    }
    
    var storageReference: StorageReference{
        return Storage.storage().reference().child("storage")
    }
    var audioReference: StorageReference{
        return Storage.storage().reference().child("storage").child("sound")
    }
    
    var messageArray = [Messages]()
    let geoCoder = CLGeocoder()
    var annotationLocation: CLLocation?

    let USER_REF = Database.database().reference().child("users")
    
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    var CURRENT_USER_EVENTS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("Events")
    }
 
    var event: Event?
    var eventID: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCurrentUserName()
        self.sendMessageTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        setupKeyboardObservers()
        self.closeListenViewButtonOutlet.roundCorners(corners: .topLeft, radius: 10)
        self.micView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        guestbookCollectionView.alwaysBounceVertical = true
        guestbookCollectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        scrollDownToBottom()
        invitationViewButtonOutlet.roundCorners(corners: [.topLeft], radius: 20)
        guestBookViewButtonOutlet.roundCorners(corners: [.topRight], radius: 20)
        downloadedImageVIew.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        guestBookView.roundCorner(corners: [.bottomLeft,.bottomRight], radius: 20)
        
        if let eventID = eventID{
            setHasBeenRead(eventID: eventID)
            
        }
        if let event = event{
            self.eventTitle.text = event.title
            self.eventDescription.text = event.description
            self.eventImage.image = UIImage(named: switchImage(typeOfEvent: event.type))
            getAdress(latitude: event.latitude, longitude: event.longitude)
            self.hostNameLabel.text = event.host
            
            //Time
            let index = event.time.index(of: "&")!
            let dateStr = event.time[..<index]
            let index2 = event.time.index(index, offsetBy: 1)
            let timeStr = event.time[index2...]
            self.dateLabel.text = String(dateStr)
            self.timeLabel.text = String(timeStr)
            
            if event.hasUnreadTextMessage == true {
                self.newTextBadge.isHidden = false
                self.newTextLabel.isHidden = false
            }
            
            //
            if let sound = event.soundRef{
                if sound != "0"{
                    micButtonView.isHidden = false
                }
            }
            if let image = event.imageRef{
                if image != "0"{
                    drawButtonView.isHidden = false
                }
            }
            getEvent(event.eventReference!)
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    func getEvent(_ eventID: String){
        Database.database().reference().child("Events").child(eventID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            for child in snapshot.childSnapshot(forPath: "invitedFriends").children {
                let snap = child as! DataSnapshot
                let key = snap.key
                
                let answerValue = snap.childSnapshot(forPath: "answer").value as! String

                
                if key == self.CURRENT_USER_ID {
                    
                    if answerValue == "Comming"{
                        self.acceptButtonPressed()
                        self.currentUserAnswer = "Comming"
                    }
                    else if answerValue == "No"{
                        self.declineButtonPressed()
                        self.currentUserAnswer = "No"
                    }
                    else {
                    }
                    self.invitedFriendsCollectionView.reloadData()
                }
            }
            
        })
    }
    
    
    func scrollDownToBottom(){
        guestbookCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
    }
    
    //MARK: Get addres for event
    func getAdress(latitude: Double, longitude: Double){
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            // Location name
            if let locationName = placeMark.name  {
                self.placeLabel.text = locationName
            }
            
            // Street address
            if let street = placeMark.thoroughfare {
                self.addressLabel.text = street
                
            }
        })
        
    }
    
    
    func switchImage(typeOfEvent: String)->String{
        switch typeOfEvent {
        case "Öl":
            return "beer"
        case "Vin":
            return "wine"
        case "Bio":
            return "popcorn"
        case "Fotboll":
            return "football-large"
        case "Kaffe":
            return "coffee-large"
        case "TV-spel":
            return "video-game_large"
        case "Gymma":
            return "gym-large"
        case "Plugga":
            return "study-large"
        case "Party":
            return "party-large"
        case "Konsert":
            return "consert-large"
        case "Promenad":
            return "walk-large"
        case "Resa":
            return "travel-large"
        case "Spela spel":
            return "board-game-large"
        case "Träna":
            return "work-out-large"
        case "Film":
            return "watch-movie-large"
        case "Drink":
            return "drinks-large"
            
        default:
            return "letter"
        }
    }
    
    func setHasBeenRead(eventID: String) {
        CURRENT_USER_EVENTS_REF.child(eventID).updateChildValues(["hasBeenRead" : true])
    }


    
    @IBAction func backgroundButton(_ sender: UIButton) {

        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    //MARK: Mic sound functions
    @IBAction func microphoneButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.micView.transform = .identity
        }, completion: nil)
        
    }
    
    @IBAction func closeListenViewButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.micView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            
        }, completion: nil)
    }
    
    @IBAction func listenButton(_ sender: UIButton) {
        downloadSound(soundReference: (event?.soundRef!)!)
    }
    
    
    func downloadSound(soundReference: String){
        let downloadSoundRef = audioReference.child(soundReference)
        
        let fileUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        guard let fileUrl = fileUrls.first?.appendingPathComponent(soundReference) else {
            return
        }
        
        let downloadTask = downloadSoundRef.write(toFile: fileUrl)
        
        downloadTask.observe(.success) { _ in
            do {
                self.player = try AVAudioPlayer(contentsOf: fileUrl)
                self.player?.prepareToPlay()
                self.player?.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    //MARK: Drawn image functions
    @IBAction func closeImageView(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.downloadedImageVIew.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: nil)
    }
    
    @IBAction func drawingImageButton(_ sender: UIButton) {
        
        downloadImage(imageRef: (event?.imageRef!)!)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.downloadedImageVIew.transform = .identity
        }, completion: nil)
    }
    
    func downloadImage(imageRef: String){
        let downloadImageRef = storageReference.child("images/\(imageRef)")
        
        downloadImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print ("IMAGE ERROR :(\(error)")
            } else {
                // Data for "images/island.jpg" is returned
                self.downloadedImage.image = UIImage(data: data!)
            }
        }
        
    }
    
    
    //MARK: Invitation answer
    @IBAction func acceptInviteButton(_ sender: UIButton) {
        acceptButtonPressed()
        getEvent((event?.eventReference!)!)
    }
    
    func acceptButtonPressed (){
        let ref = Database.database().reference().child("Events").child((event?.eventReference)!).child("invitedFriends").child(CURRENT_USER_ID).child("answer")
        ref.setValue("Comming")
        
        acceptButtonOutlet.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        declineButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        acceptButtonOutlet.setTitle("Accepted!", for: .normal)
        acceptButtonOutlet.isEnabled = false
        declineButtonOutlet.isEnabled = true
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.acceptButtonOutlet.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.declineButtonOutlet.transform = .identity
            self.declineButtonOutlet.setTitle("Decline", for: .normal)
        }) { (success) in
            
        }
        
    }
    
    @IBAction func declineInviteButton(_ sender: UIButton) {
        declineButtonPressed()
        getEvent((event?.eventReference!)!)
    }
    
    func declineButtonPressed(){
        let ref = Database.database().reference().child("Events").child((event?.eventReference)!).child("invitedFriends").child(CURRENT_USER_ID).child("answer")
        ref.setValue("No")
        declineButtonOutlet.setTitle("Declined!", for: .normal)
        acceptButtonOutlet.isEnabled = true
        declineButtonOutlet.isEnabled = false
        declineButtonOutlet.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        acceptButtonOutlet.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.declineButtonOutlet.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.acceptButtonOutlet.transform = .identity
            self.acceptButtonOutlet.setTitle("Accept", for: .normal)
        }) { (success) in
        }
    }
   
    @IBAction func invitationViewButton(_ sender: UIButton) {
        guestBookView.isHidden = true
        commentsRef.removeObserver(withHandle: handle)
        self.invitationViewButtonOutlet.backgroundColor = PURPLE_COLOR
        self.invitationViewButtonOutlet.setTitleColor(UIColor.white, for: .normal)
        self.guestBookViewButtonOutlet.backgroundColor = UIColor.white
        self.guestBookViewButtonOutlet.setTitleColor(PURPLE_COLOR, for: .normal)
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    var constraint: NSLayoutConstraint?
    
    @objc func keyboardWillShow(notification: Notification){
        scrollDownToBottom()
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double)
        
        self.constraint = self.popUpView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(keyboardFrame?.height)!-51)
        self.constraint!.isActive = true
        
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func keyboardWillHide(notification: Notification){
        
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double)
        constraint?.isActive = false
        
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    //MARK: COLLECTIONVIEWS
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.guestbookCollectionView{
            return messageArray.count
        }
        else{
            return event!.invitedFriends.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.guestbookCollectionView{
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCell", for: indexPath) as! MessageCell
            cell.textView.text = messageArray[indexPath.row].message
            if messageArray[indexPath.row].ID == CURRENT_USER_ID {
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
                for friend in (event?.invitedFriends)!{
                    let _ = friend.map({ (key, value) -> Void in
                        if key == messageArray[indexPath.row].ID{
                            let _ = value.map({ (email, answer) -> Void in
                                cell.userLabel.text = email
                            })
                        }
                    })
                }
            }
            cell.bubbleWidthAnchor?.constant = estimatedHeightForText(text: messageArray[indexPath.row].message).width + 30
            return cell
            
        }
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "invitedFriendsCell", for: indexPath) as! InvitedFriendsCell
        
        let _ = event?.invitedFriends[indexPath.row].map({ (key, value) -> Void in
            
            let _ = value.map({ (mail, answer) -> Void in
                cell.nameLabel.text = mail
                if key == CURRENT_USER_ID {
                    self.currentUserName = mail
                    if (self.currentUserAnswer == "Comming"){
                        cell.answerIcon.image = UIImage(named: "check")
                        cell.answerIcon.isHidden = false
                        cell.backgroundToCell.layer.borderColor = UIColor(red:0/255, green:255/255, blue:0/255, alpha: 1).cgColor
                    }
                    else if (self.currentUserAnswer == "No"){
                        cell.answerIcon.isHidden = false
                        cell.answerIcon.image = UIImage(named: "cross")
                        
                        cell.backgroundToCell.layer.borderColor = UIColor(red:255/255, green:0/255, blue:0/255, alpha: 1).cgColor
                    }
                }
                else {
                    if(answer=="Comming"){
                        cell.answerIcon.image = UIImage(named: "check")
                        cell.answerIcon.isHidden = false
                        cell.backgroundToCell.layer.borderColor = UIColor(red:0/255, green:255/255, blue:0/255, alpha: 1).cgColor
                    }
                    else if(answer=="No"){
                        cell.answerIcon.image = UIImage(named: "cross")
                        cell.answerIcon.isHidden = false
                        cell.backgroundToCell.layer.borderColor = UIColor(red:255/255, green:0/255, blue:0/255, alpha: 1).cgColor
                    }
                    else {
                        cell.answerIcon.isHidden = true
                        cell.backgroundToCell.layer.borderColor = PURPLE_COLOR.cgColor
                    }
                }
            })
        })
 
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (collectionView == guestbookCollectionView){
            var height: CGFloat = 80
            
            
            height = estimatedHeightForText(text: messageArray[indexPath.item].message).height + 50
            
            
            return CGSize(width: guestbookCollectionView.frame.width, height: height)
        }
        else {
            return CGSize(width: 50, height: 50)
        }
    }
    
    //Get height for text bubbles
    private func estimatedHeightForText(text: String)-> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)], context: nil)
    }
    
    
    // MARK: - SEND PUSH NOTIFICATIONS
    func sendPushNotification(key: String){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if (key != uid){
            let ref = Database.database().reference().child("messages").child(uid)
            let messageText = "\(key) invited you to a new event!"
            
            let value = ["message": messageText, "fromDevice":AppDelegate.DEVICEID, "fromID":uid, "toID": key] as [String:Any]
            ref.updateChildValues(value)
            self.fetchMessage(toID: key)
        }
    }
    
    func fetchMessage(toID: String){
        Database.database().reference().child("users").child(toID).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else {return}
            let fromDevice = dictionary["fromDevice"] as! String
            self.setUpPushNotification(fromDevice: fromDevice)
            
        }
    }
    
    func setUpPushNotification(fromDevice: String){
        let message = "\(currentUserName) wrote a message in the guestbook!"
        let title = "New textbook message"
        let body = message
        let toDeviceID = fromDevice
        var headers: HTTPHeaders =   HTTPHeaders()
        
        headers = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
    
        let notification = ["to":"\(toDeviceID)", "notification":["body":body, "title":title, "badge":1, "sound":"default"]] as [String : Any]
        
        Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
    }
    
    
    //MARK: GUESTBOOK Messages
    @IBAction func guestBookViewButton(_ sender: UIButton) {
        //   Tell firebase that current user read latest guestbook post
        self.newTextLabel.isHidden = true
        self.newTextBadge.isHidden = true
        self.observeGuestbookMessages()
        Database.database().reference().child("Events").child((event?.eventReference)!).child("invitedFriends").child(CURRENT_USER_ID).updateChildValues(["newTextMessage" : false])
        
        guestBookView.isHidden = false
        self.guestbookCollectionView.reloadData()
        self.invitationViewButtonOutlet.backgroundColor = UIColor.white
        self.invitationViewButtonOutlet.setTitleColor(PURPLE_COLOR, for: .normal)
        self.guestBookViewButtonOutlet.backgroundColor = PURPLE_COLOR
        self.guestBookViewButtonOutlet.setTitleColor(UIColor.white, for: .normal)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        scrollDownToBottom()
        sendMessage()
        for friend in (event?.invitedFriends)!{
            let _ = friend.map({ (ID, value) -> () in
                if (ID != CURRENT_USER_ID) {
                    self.sendPushNotification(key: ID)
                    Database.database().reference().child("Events").child((event?.eventReference)!).child("invitedFriends").child(ID).updateChildValues(["newTextMessage" : true])
                }
            })
        }
    }
    
    func sendMessage(){
        let ref = Database.database().reference().child("Events").child((event?.eventReference)!).child("guestBook")
        let childRef = ref.childByAutoId()
        if sendMessageTextField.text != "" {
            let value = ["text": sendMessageTextField.text!, "from": String(CURRENT_USER_ID), "timeStamp": Int(Date.timeIntervalSinceReferenceDate)] as [String: Any]
            
            childRef.updateChildValues(value)
            self.sendMessageTextField.text = ""
        }
    }
    
    var handle: UInt = 0
    var commentsRef: DatabaseReference {
        return Database.database().reference().child("Events").child((event?.eventReference!)!).child("guestBook")
    }
    
    func observeGuestbookMessages() {
        
        self.messageArray.removeAll()
        
        handle = commentsRef.observe(.childAdded, with: { (snapshot) -> Void in
            let text = snapshot.childSnapshot(forPath: "text").value as! String
            let time = snapshot.childSnapshot(forPath: "timeStamp").value as! Int
            let from = snapshot.childSnapshot(forPath: "from").value as! String
            let newMessage = Messages(id: from, message: text, timeStamp: time)
            self.messageArray.append(newMessage)
            self.guestbookCollectionView.reloadData()
            let lastItemIndex = IndexPath(item: (self.messageArray.count)-1, section: 0)
            self.guestbookCollectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: false)
        })
    }
    
    
    //MARK: Get directions from apple maps
    @IBAction func getDirectionsButton(_ sender: UIButton) {
        if let latitude = event?.latitude{
            if let longitude = event?.longitude{
                let regionDistance: CLLocationDistance = 10000
                let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
                
                let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)]
                let placemark = MKPlacemark(coordinate: coordinates)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = "Event adress"
                mapItem.openInMaps(launchOptions: options)
                
            }
        }
        else {
            self.alert(title: "Location not available", message: "The location of the event is invalid")
        }
        
    }

    
    
    
}



























