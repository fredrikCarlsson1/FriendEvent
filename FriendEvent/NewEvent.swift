//
//  NewEvent.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-09.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import Alamofire
import FirebaseMessaging
import FirebaseInstanceID
import UserNotifications
import AVFoundation


class NewEvent: UIViewController, MKMapViewDelegate, UISearchBarDelegate, MessagingDelegate, UICollectionViewDelegate, UICollectionViewDataSource, AVAudioRecorderDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate, CLLocationManagerDelegate  {
 var storageReference: StorageReference{
        return Storage.storage().reference().child("storage")
    }
    
    //MARK: MAP VARIBLES
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var myMapView: MKMapView!

    //MARK: FRIEND VARIBLES
    var friendList = [User]()
    var selectedFriends = [User]()
    let USER_REF = Database.database().reference().child("users")
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    var CURRENT_USER_FRIENDS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("friends")
    }
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    var checkMarks = [UIImageView]()
    
    var CURRENT_USER_EMAIL: String {
        let email = Auth.auth().currentUser!.email
        return email!
    }
    
    var CURRENT_USERNAME: String?
    
    func setCurrentUserName (){
        CURRENT_USER_REF.observeSingleEvent(of: .value) { (snapshot) in
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            self.CURRENT_USERNAME = name
        }
    }
    
    //MARK: POPUP VARIBLES
    @IBOutlet weak var popUpView: UIViewX!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var firstCollectionView: UICollectionView!
    @IBOutlet weak var eventDescriptionView: UITextView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var typeOfEventSelectorOutlet: UIButton!
    
    @IBOutlet weak var viewBehindPickerWheel: UIView!
    @IBOutlet weak var pickerWheel: UIPickerView!
    @IBOutlet weak var imageView: UIImageViewX!
    @IBOutlet weak var backgroundButtonOutlet: UIButton!
    
    @IBOutlet weak var textFieldPlaceholder: UILabel!
    
    
    //MARK: DRAWING VARIBLES
    @IBOutlet weak var drawingView: UIView!
    var sendImage = UIImageView()
    @IBOutlet weak var canvas: UIImageView!
    var start: CGPoint?
    var paintColor: CGColor = UIColor.black.cgColor
    var lineWidht: CGFloat = 5
    var maxLineWidth: CGFloat = 20
    var minLineWidth: CGFloat = 2
    var deltaLineWidth: CGFloat = 2
    var drawingReference: String?
    
    @IBOutlet weak var closeDrawingViewOutlet: UIButton!
    
    
    //MARK: MICROPHONE VARIBLES
    @IBOutlet weak var micView: UIView!
    var player: AVAudioPlayer?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var soundRef: String?
    
    @IBOutlet weak var labelUnderStartRecording: UILabel!
    @IBOutlet weak var closeMicViewButtonOutlet: UIButton!
    @IBOutlet weak var recordingButtonLabel: UIButton!
    @IBOutlet weak var timeLabelOverRecord: UILabel!
    var countdownTimer = 10
    var timer = Timer()
    
    
    //MARK: DISPLAY LOCATION VARIBLES
    let geoCoder = CLGeocoder()
    var annotationLocation: CLLocation?
    var place: String = ""
    var adress: String = ""
    
    
    //MARK: OTHER VARIBLES
    var dateTime: String?
    var timeTime: String?
    var totalTime = ""
    let PURPLE_COLOR = UIColor(hexString: "#8F6886")
    var typeOfEvent: String?
    var pickerWheelSelections = [String]()
    var myTimeStamp: Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardObservers()
        setCurrentUserName()
        pickerWheelSelections = ["– Select type of event –", "Vin", "Middag", "Öl", "Bio"]
        
        imageView.roundCorners(corners: [.topRight, .topLeft], radius: 15)
        closeMicViewButtonOutlet.roundCorners(corners: .topLeft, radius: 10)
        closeDrawingViewOutlet.roundCorners(corners: .topLeft, radius: 10)
        canvas.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        
        addFriendObserver()
        searchBar.delegate = self
        popUpView.alpha = 0
        drawingView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        micView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        
        
        textFieldPlaceholder.isHidden = !eventDescriptionView.text.isEmpty
        eventDescriptionView.delegate = self
        firstCollectionView.delegate = self
        firstCollectionView.dataSource = self
        
        
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        myMapView.addGestureRecognizer(gestureRecognizer)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        myMapView.showsUserLocation = true
        zoomInOnLocation()
    }
    
    //MARK: MAP FUNCTIONS
    func zoomInOnLocation() {
        
        //get location
        let location = myMapView.userLocation.coordinate
        let latitude = location.latitude
        let longitude = location.longitude
        
        //Zooming in on annotation
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let span = MKCoordinateSpanMake(0.3, 0.3)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.myMapView.setRegion(region, animated: true)
    }
    
    @objc func handleTap(_ gestureReconizer: UILongPressGestureRecognizer) {
        let location = gestureReconizer.location(in: myMapView)
        let coordinate = myMapView.convert(location,toCoordinateFrom: myMapView)
        
//        // Add annotation:
//        let annotation = MKPointAnnotation()
//        annotation.coordinate = coordinate
//        myMapView.addAnnotation(annotation)
    
        self.placeAnnotation(latitude: coordinate.latitude, longitude: coordinate.longitude)
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
            annotationView.annotation = annotation
        }
        annotationView.image = UIImage(named: "cross")
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
        annotationView.addSubview(button)
        let transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        annotationView.transform = transform
        return annotationView
        }
        else {
            return nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        self.datePickerOutlet.isHidden = true
        self.pickerWheel.isHidden = true
        viewBehindPickerWheel.alpha = 0
        
        if let touch = touches.first{
            self.start = touch.location(in: canvas)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control as? UIButton)?.buttonType ==   UIButtonType.detailDisclosure {
            pressed()
        }
    }
    
    @objc func buttonAction(sender: UIButton!) {
        pressed()
    }
    
    func pressed() {
        setLocation()
        firstCollectionView.reloadData()
        popUpView.transform = CGAffineTransform(scaleX: 0.4, y: 1.8)
        backgroundButtonOutlet.isHidden = false
        blurView.isHidden = false
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.popUpView.transform = .identity
        }) { (success) in
            
        }
        popUpView.alpha = 1
    }
    
    
    //MARK: SEARCH FUNCTIONS
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        getSearchRequest()
        self.view.endEditing(true)
    }
    
    func getSearchRequest (){
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            if response == nil
            {
                self.alert(title: "Oops", message: "Could not find location")
            }
            else{
                //get data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                self.placeAnnotation(latitude: latitude!, longitude: longitude!)

            }
        }
    }
    
    func placeAnnotation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        //remove annotation
        let annotations = self.myMapView.annotations
        self.myMapView.removeAnnotations(annotations)
        
        
        //create annotation
        let annotation = MKPointAnnotation()
        annotation.title = self.searchBar.text
        annotation.subtitle = "Klick to invite friends"
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        self.myMapView.addAnnotation(annotation)
        
        //Zooming in on annotation
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        self.annotationLocation = CLLocation(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.myMapView.setRegion(region, animated: true)
    }
    
    
    //MARK: COLLECTIONVIEW FUNCTIONS
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.firstCollectionView {
            return 4
        }
        else {
            return friendList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.firstCollectionView {
            if indexPath.section == 0 {
                switch indexPath.item{
                case 0:
                    let cell1 =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell1", for: indexPath) as! ReusableButtonCell
                    
                    if let time = dateTime{
                        cell1.dateLabel.text = time
                    }
                    if let time = timeTime{
                        cell1.dateUnderLabel.text = time
                    }
                    
                    return cell1
                case 1:
                    let cell3 =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell3", for: indexPath) as! ReusableButtonCell
                    cell3.micButtonOutlet.imageView?.contentMode = .scaleAspectFit
                    
                    return cell3
                case 2:
                    let cell2 =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! ReusableButtonCell
                    cell2.locationTitleLabel.text = self.place
                    
                    if let location = annotationLocation {
                        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                            
                            // Place details
                            var placeMark: CLPlacemark!
                            placeMark = placemarks?[0]

                            // Street address
                            if let street = placeMark.thoroughfare {
                                cell2.locationDescriptionLabel.text = street
                            }
                        })
                    }
                    
                    return cell2
                case 3:
                    let cell4 = collectionView.dequeueReusableCell(withReuseIdentifier: "cell4", for: indexPath) as! ReusableButtonCell
                    cell4.drawButtonOutlet.imageView?.contentMode = .scaleAspectFit
                    return cell4
                default:
                    return collectionView.dequeueReusableCell(withReuseIdentifier: "cell1", for: indexPath)
                }
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reusableButtonCell", for: indexPath) as! ReusableButtonCell
        cell.button.tag = indexPath.row
        cell.button.backgroundColor = UIColor.white
        let checkMark = UIImageView()
        checkMark.image = UIImage(named: "black-check-mark-hi")
        checkMark.frame = CGRect(x: cell.button.frame.width - 15, y: 10, width: 10, height: 10)
        checkMark.alpha = 1
        checkMarks.append(checkMark)
        cell.label.text = friendList[indexPath.row].name
        cell.button.addTarget(self, action: #selector(selectFriend(_:)), for: .touchUpInside)
        return cell
        
    }
    
    //MARK: DRAWING FUNCTIONS
    @IBAction func drawingButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.drawingView.transform = .identity
        }, completion: nil)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            let end = touch.location(in: canvas)
            if let start = self.start {
                drawFromPoint(start: start, toPoint: end)
                //rita line från start till end
            }
            self.start = end
        }
        
    }
    
    
    func drawFromPoint(start : CGPoint, toPoint end: CGPoint){
        UIGraphicsBeginImageContext(canvas.frame.size)
        canvas.image?.draw(in: CGRect(x: 0, y: 0, width: canvas.frame.size.width, height: canvas.frame.size.height))
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(paintColor)
            context.setLineWidth(lineWidht)
            context.setLineCap(.round)
            context.beginPath()
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            canvas.image = newImage
        }
    }
    
    @IBAction func clearImage(_ sender: UIButton) {
        canvas.image = nil
    }
    
    @IBAction func closeDrawingButton(_ sender: UIButton) {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.drawingView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: nil)
        
    }
    
    @IBAction func saveDrawingImage(_ sender: UIButton) {
        sendImage.image = canvas.image
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.drawingView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: nil)
        
        
    }
    
    @IBAction func colorButton(_ sender: UIButton) {
        paintColor = (sender.tintColor.cgColor)
    }
    
    func uploadDrawnImage(){
        
        guard let image = sendImage.image else {return}
        guard let imageData = UIImageJPEGRepresentation(image, 1) else {return}
        
        self.drawingReference = "\(CURRENT_USER_ID)\(self.generateRandomNumber())"
        
        let uploadRef = storageReference.child("images").child(drawingReference!)
        
        
        let uploadTask = uploadRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
            
        })
        uploadTask.resume()
        
    }
    
    
        @IBAction func increaseWidth(_ sender: UIButton) {
            if (lineWidht<maxLineWidth){
                lineWidht = lineWidht + deltaLineWidth
            }
        }
        @IBAction func decreaseWidth(_ sender: UIButton) {
            if(lineWidht>minLineWidth){
                lineWidht = lineWidht - deltaLineWidth
            }
        }
    
    
    
    
    //MARK: ADD FRIENDS TO EVENT FUNCTIONS
    @objc func selectFriend(_ button : UIButton){
        if(button.backgroundColor == UIColor.white){
            button.backgroundColor = PURPLE_COLOR
            button.addSubview(checkMarks[button.tag])
            self.selectedFriends.append(friendList[button.tag])
            checkMarks[button.tag].alpha = 1
        }
        else if(button.backgroundColor == PURPLE_COLOR){
            button.backgroundColor = UIColor.white
            checkMarks[button.tag].alpha = 0
            var index = 0
            for friend in selectedFriends{
                if (friend.id == friendList[button.tag].id){
                    self.selectedFriends.remove(at: index)
                }
                index += 1
            }
        }
    }
    
    func addFriendObserver() {
        CURRENT_USER_FRIENDS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.friendList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.getUser(id, completion: { (user) in
                    self.friendList.append(user)
                    self.collectionView.reloadData()
                })
            }
            if snapshot.childrenCount == 0 {
            }
        })
    }
    
    func getUser(_ userID: String, completion: @escaping (User) -> Void) {
        USER_REF.child(userID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let email = snapshot.childSnapshot(forPath: "Email").value as! String
            let id = snapshot.key
            let name = snapshot.childSnapshot(forPath: "username").value as! String
            completion(User(email: email, userID: id, name: name))
        })
    }
    
    
    // MARK: - SEND PUSH NOTIFICATIONS
    func sendMessage(key: String){

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
        let message = "\(CURRENT_USERNAME!) invited you to a new event!"
        
        let title = "Quick Inviter"
        let body = message
        let toDeviceID = fromDevice
        var headers: HTTPHeaders =   HTTPHeaders()
        
        headers = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
        
        let notification = ["to":"\(toDeviceID)", "notification":["body":body, "title":title, "badge":1, "sound":"default"]] as [String : Any]
        
        Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
    }
    
    
    //MARK: SEND INVITATION
    func sendInvite(){
        let host = User(email: CURRENT_USER_EMAIL, userID: CURRENT_USER_ID, name: CURRENT_USERNAME!)
        
        if(titleTextField.text != ""){
            if(selectedFriends.count != 0){
                if(totalTime != "") {
                    let position = ["latitude": Double((annotationLocation?.coordinate.latitude)!), "longitude": Double((annotationLocation?.coordinate.longitude)!)] as [String: Double]
                    let posts = ["sender": String(CURRENT_USER_ID), "title": titleTextField.text!, "description": self.eventDescriptionView.text, "time": String(totalTime), "imageRef": self.drawingReference ?? "0", "soundRef": self.soundRef ?? "0", "position": position, "eventType": typeOfEvent ?? "0"] as [String : Any]
                    
                    let eventID = "\(CURRENT_USER_ID)\(generateRandomNumber())\(generateRandomNumber())"
                    let ref = Database.database().reference().child("Events").child(eventID)
                    ref.updateChildValues(posts)
                    
                    if let hostUsername = CURRENT_USERNAME{
                        let post2 = ["host": hostUsername]
                        ref.updateChildValues(post2)
                    }
                    
                    let key = USER_REF.child(CURRENT_USER_ID).child("posts").childByAutoId().key
                    let childUpdates = ["/Events/\(key)/": ["eventID": eventID, "hasBeenRead": true, "timeStamp": self.myTimeStamp ?? 0]] as [String: Any]
                    CURRENT_USER_REF.updateChildValues(childUpdates)
                    let host1 = ["name": String(host.name), "answer": "Comming", "newTextMessage": false] as [String : Any]
                    ref.child("invitedFriends").child(CURRENT_USER_ID).updateChildValues(host1)
                    
                    for friend in selectedFriends{
                        let post3 = ["name": String(friend.name), "answer": "TBA", "newTextMessage": false] as [String: Any]
                        ref.child("invitedFriends").child(friend.id).updateChildValues(post3)
                    }
                    for friend in selectedFriends{
                        sendEventRefToUser(eventRef: String(eventID), userID: friend.id)
                    }
                }
                else {
                    alert(title: "Missing information", message: "You need to select a date for your event")
                }
            }else {
                alert(title: "Select friends to your event", message: "You need to select at least one guest to your event")
            }
        }else {
            displayAlert(title: "Missing event-title", message: "You need to enter the name of your event")
        }
  
    }
    
    func sendEventRefToUser(eventRef: String, userID: String){
        let key = USER_REF.child(userID).child("posts").childByAutoId().key
        let childUpdates = ["/\(userID)/Events/\(key)/": ["eventID": eventRef, "hasBeenRead": false, "timeStamp": self.myTimeStamp ?? 0]] as [String: Any]
        USER_REF.updateChildValues(childUpdates)

        sendMessage(key: userID)
        
        
    }
    
    @IBAction func sendInviteButton(_ sender: UIButton) {
        uploadDrawnImage()
        popUpView.alpha = 0
        sendInvite()
        self.blurView.isHidden = true
        alert(title: "Invite sent", message: "Enjoy your upcomming event")
    }
    
    
    //MARK: SET DATE AND TIME ON EVENT FUNCTIONS
    @IBAction func selectDateButton(_ sender: UIButton) {
        datePickerOutlet.isHidden = false
        pickerWheel.isHidden = true
        viewBehindPickerWheel.alpha = 1.0
        self.buttonToClosePickerWheelAndKeyboard.isHidden = false
    }
    
    @IBAction func datePicker(_ sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: datePickerOutlet.date)
        let strTime = timeFormatter.string(from: datePickerOutlet.date)
        
        myTimeStamp = Int((self.datePickerOutlet?.date.timeIntervalSince1970)!)
        
        
        self.dateTime = "\(strDate)"
        self.timeTime = "\(strTime)"
        self.totalTime = "\(strDate) &\(strTime)"
        firstCollectionView.reloadData()
        
    }
    
    @IBOutlet weak var datePickerOutlet: UIDatePicker!
    
    
    //MARK: SET LOCATION IN POPUP
    
    @IBAction func locationButtonPressed(_ sender: UIButton) {
        
    }
    
    func setLocation(){
        if let searchText = searchBar.text{
            self.place = searchText
        }
    }
    
    //MARK: ADD MICROPHONE SOUND
    @IBAction func microphoneButtonPressed(_ sender: UIButton) {
        recordingSession = AVAudioSession.sharedInstance()
        
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission{
                
            }
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.micView.transform = .identity
        }, completion: nil)
    }
    
    @IBAction func recordButton(_ sender: UIButton) {
        
        
        if audioRecorder == nil{
            let filename = getDirectory().appendingPathComponent("track.m4a")
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            do{
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(NewEvent.clock), userInfo: nil, repeats: true)
                audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
                
                audioRecorder.delegate = self
                audioRecorder.record()
                audioRecorder.stop()
                SetSessionPlayerOn()
                audioRecorder.record()
                labelUnderStartRecording.text = "Stop recording"
            }
            catch{
                displayAlert(title: "Error", message: "Recording failed")
            }
        }
        else {
            timer.invalidate()
            timeLabelOverRecord.text = "10"
            countdownTimer = 10
            audioRecorder.stop()
            SetSessionPlayerOff()
            audioRecorder = nil
            labelUnderStartRecording.text = "Press to start recording"
            
            
            
        }
    }
    
    func SetSessionPlayerOn() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch _ {
        }
    }
    
    func SetSessionPlayerOff() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch _ {
        }
    }
    
    func getDirectory() -> URL{
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = path[0]
        return documentDirectory
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func listenToRecording(_ sender: UIButton) {
        let filename = getDirectory().appendingPathComponent("track.m4a")
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: filename)
            audioPlayer.play()
        }
        catch{
            alert(title: "Error", message: (error.localizedDescription))
        }
        
    }
    
    @IBAction func uploadSoundButton(_ sender: UIButton) {
        uploadSound()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.micView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: nil)
    }
    
    func uploadSound() {
        let localFile = getDirectory().appendingPathComponent("track.m4a")
        soundRef = "\(CURRENT_USER_ID)\(generateRandomNumber())"
        
        let uploadRef = storageReference.child("sound").child(soundRef!)
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        
        let uploadTask = uploadRef.putFile(from: localFile, metadata: metadata) { metadata, error in
            if let error = error {
                self.displayAlert(title: "Something went wrong", message: error as! String)
                // Uh-oh, an error occurred!
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                //let downloadURL = metadata!.downloadURL()
            }
        }
        uploadTask.resume()
    }
    
    @IBAction func closeRecordingView(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.micView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: nil)
    }
    
    @objc func clock() {
        countdownTimer = countdownTimer-1
        timeLabelOverRecord.text = String(countdownTimer)
     
        if (countdownTimer == 0){
            audioRecorder.stop()
            labelUnderStartRecording.text = "Press to start recording"
            timer.invalidate()
            timeLabelOverRecord.text = "10"
            countdownTimer = 10
        }
    }
    
    
    //MARK: SELECT TYPE OF EVENT
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerWheelSelections.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerWheelSelections[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeOfEventSelectorOutlet.setTitle(pickerWheelSelections[row], for: .normal)
        self.typeOfEvent = pickerWheelSelections[row]
        switch typeOfEvent! {
        case "Öl":
            self.imageView.image = UIImage(named: "beer")
        case "Vin":
            self.imageView.image = UIImage(named: "wine")
        case "Bio":
            self.imageView.image = UIImage(named: "popcorn")
        case "Middag":
            self.imageView.image = UIImage(named: "dinner")
        default:
            self.imageView.image = UIImage(named: "letter")
        }
    }
    
    //MARK: OTHER FUNCTIONS
    func generateRandomNumber()->Int{
        let random = arc4random_uniform(1000000)
        return Int(random)
    }
    
    @IBAction func typeOfEventSelector(_ sender: UIButton) {
        pickerWheel.isHidden = false
        datePickerOutlet.isHidden = true
        self.buttonToClosePickerWheelAndKeyboard.isHidden = false
        self.viewBehindPickerWheel.alpha = 1
    }
    
    @IBAction func backgroundButton(_ sender: UIButton) {
        popUpView.alpha = 0
        blurView.isHidden = true
        backgroundButtonOutlet.isHidden = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textFieldPlaceholder.isHidden = true
    }
    
    @IBOutlet weak var buttonToClosePickerWheelAndKeyboard: UIButton!
    
    @IBAction func buttonToCloseKeyboardAndPickerView(_ sender: UIButton) {
        view.endEditing(true)
        self.pickerWheel.isHidden = true
        self.datePickerOutlet.isHidden = true
        self.viewBehindPickerWheel.alpha = 0
        self.buttonToClosePickerWheelAndKeyboard.isHidden = true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    var bottomConstraint: NSLayoutConstraint?
    var topConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var eventDiscriptionContainerView: UIViewX!
    
    @objc func keyboardWillShow(notification: Notification){
        self.buttonToClosePickerWheelAndKeyboard.isHidden = false
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double)
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        
        
        self.topConstraint = self.eventDiscriptionContainerView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -(keyboardFrame?.height)!-200)
        self.bottomConstraint = self.eventDiscriptionContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(keyboardFrame?.height)!-81)
        
        self.bottomConstraint!.isActive = true
        self.topConstraint!.isActive = true
        
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: Notification){
        
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double)
        
        self.bottomConstraint?.isActive = false
        self.topConstraint?.isActive = false
        
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    
}



















