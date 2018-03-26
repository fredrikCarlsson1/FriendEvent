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


class NewEvent: UIViewController, MKMapViewDelegate, UISearchBarDelegate, MessagingDelegate, UICollectionViewDelegate, UICollectionViewDataSource, AVAudioRecorderDelegate  {
    

    
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
    
    //MARK: POPUP VARIBLES
    @IBOutlet weak var popUpView: UIViewX!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var firstCollectionView: UICollectionView!
    @IBOutlet weak var eventDescriptionView: UITextView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var typeOfEventSelectorOutlet: UIButton!
    @IBOutlet weak var viewBehindPickerWheels: UIDatePicker!
    
    //MARK: DRAWING VARIBLES
    @IBOutlet weak var drawingView: UIView!
    var sendImage = UIImageView()
    @IBOutlet weak var canvas: UIImageView!
    var start: CGPoint?
    var paintColor: CGColor = UIColor.blue.cgColor
    var lineWidht: CGFloat = 5
    var maxLineWidth: CGFloat = 20
    var minLineWidth: CGFloat = 2
    var deltaLineWidth: CGFloat = 2
    var drawingReference: String?
    
    //MARK: MICROPHONE VARIBLES
    @IBOutlet weak var micView: UIView!
    var player: AVAudioPlayer?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var soundRef: String?
    
    @IBOutlet weak var recordingButtonLabel: UIButton!
    
    
    //MARK: DISPLAY LOCATION VARIBLES
    let geoCoder = CLGeocoder()
    var annotationLocation: CLLocation?
    var place: String = ""
    var adress: String = ""
    
    
    //MARK: OTHER VARIBLES
    var dateTime: String = ""
    var timeTime: String?
    var downloadedImage = UIImageView()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFriendObserver()
        searchBar.delegate = self
        popUpView.alpha = 0
        drawingView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        micView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        
        
        firstCollectionView.delegate = self
        firstCollectionView.dataSource = self
        
    }
    
    
    
    //MARK: MAP FUNCTIONS
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "annotation")
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
            view?.canShowCallout = true
            view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            view?.annotation = annotation
        }
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
        view?.addSubview(button)
        return view
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        self.datePickerOutlet.isHidden = true
        self.viewBehindPickerWheels.isHidden = true
        
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
                print("error")
            }
            else{
                //remove annotation
                let annotations = self.myMapView.annotations
                self.myMapView.removeAnnotations(annotations)
                
                //get data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                //create annotation
                let annotation = MKPointAnnotation()
                annotation.title = self.searchBar.text
                annotation.subtitle = "Klick to invite friends"
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.myMapView.addAnnotation(annotation)
                
                //Zooming in on annotation
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.annotationLocation = CLLocation(latitude: latitude!, longitude: longitude!)
                let span = MKCoordinateSpanMake(0.1, 0.1)
                let region = MKCoordinateRegionMake(coordinate, span)
                self.myMapView.setRegion(region, animated: true)
                
            }
        }
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
                    
                        cell1.dateLabel.text = dateTime
                    
                    if let time = timeTime{
                        cell1.dateUnderLabel.text = time
                    }
                    
                    return cell1
                case 1:
                    return collectionView.dequeueReusableCell(withReuseIdentifier: "cell3", for: indexPath)
                case 2:
                    let cell2 =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! ReusableButtonCell
                    cell2.locationTitleLabel.text = self.place
                    
                    if let location = annotationLocation {
                        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                            
                            // Place details
                            var placeMark: CLPlacemark!
                            placeMark = placemarks?[0]
                            
                            //                            // Complete address as PostalAddress
                            //                            print(placeMark.postalCode as Any)  //  Import Contacts
                            //
                            //                            // Location name
                            //                            if let locationName = placeMark.name  {
                            //                                print (locationName)
                            //                            }
                            
                            // Street address
                            if let street = placeMark.thoroughfare {
                                print(street)
                                
                                cell2.locationDescriptionLabel.text = street
                            }
                            
                            //                            // Country
                            //                            if let country = placeMark.country {
                            //                                print(country)
                            //                            }
                        })
                    }
                    
                    return cell2
                case 3:
                    return collectionView.dequeueReusableCell(withReuseIdentifier: "cell4", for: indexPath)
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
        cell.label.text = friendList[indexPath.row].email
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
        paintColor = (sender.backgroundColor?.cgColor)!
    }
    
    func uploadDrawnImage(){
        
        guard let image = sendImage.image else {return}
        guard let imageData = UIImageJPEGRepresentation(image, 1) else {return}
        
        self.drawingReference = "\(CURRENT_USER_ID)\(self.generateRandomNumber())"
        
        let uploadRef = storageReference.child("images").child(drawingReference!)
        
        
        let uploadTask = uploadRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
            print("UPLOAD TASK FINISHED")
            print(metadata ?? "NO meta data")
            print(error ?? "NO error")
        })
        uploadTask.resume()
        print("DDDDDDDDDOOOOOOOOONE")
    }
    
    func downloadImage(){
        let downloadImageRef = storageReference.child("storage")
        
        let downloadTask = downloadImageRef.getData(maxSize: 1024*1024*15) { (data, error) in
            if let data = data {
                let image = UIImage(data: data)
                self.downloadedImage.image = image
            }
            print(error ?? "No ERROR")
        }
        downloadTask.resume()
    }
    
    
    //    @IBAction func increaseWidth(_ sender: UIBarButtonItem) {
    //        if (lineWidht<maxLineWidth){
    //            lineWidht = lineWidht + deltaLineWidth
    //        }
    //    }
    //    @IBAction func decreaseWidth(_ sender: UIBarButtonItem) {
    //        if(lineWidht>minLineWidth){
    //            lineWidht = lineWidht - deltaLineWidth
    //        }
    //    }
    
    
    
    
    
    
    //MARK: ADD FRIENDS TO EVENT FUNCTIONS
    @objc func selectFriend(_ button : UIButton){
        if(button.backgroundColor == UIColor.white){
            button.backgroundColor = UIColor.cyan
            button.addSubview(checkMarks[button.tag])
            self.selectedFriends.append(friendList[button.tag])
            checkMarks[button.tag].alpha = 1
        }
        else if(button.backgroundColor == UIColor.cyan){
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
            completion(User(email: email, userID: id))
        })
    }
    
    
    // MARK: - SEND PUSH NOTIFICATIONS
    func sendMessage(key: String){
        //        Database.database().reference().child("users").observeSingleEvent(of: .value) { (snapshot) in
        //            guard let dictionary = snapshot.value as? [String:Any] else {return}
        //
        //            dictionary.forEach({ (key, value) in
        //
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if (key != uid){
            let ref = Database.database().reference().child("messages").child(uid)
            let messageText = "\(key) invited you to a new event!"
            
            let value = ["message": messageText, "fromDevice":AppDelegate.DEVICEID, "fromID":uid, "toID": key] as [String:Any]
            
            ref.updateChildValues(value)
            
            self.fetchMessage(toID: key)
        }
        //            })
        //        }
    }
    
    func fetchMessage(toID: String){
        Database.database().reference().child("users").child(toID).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else {return}
            let fromDevice = dictionary["fromDevice"] as! String
            self.setUpPushNotification(fromDevice: fromDevice)
            
        }
    }
    
    func setUpPushNotification(fromDevice: String){
        let message = "\("XXX") invited you to a new event!"
        
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
    func sendInvite(userID: String){
        //        CURRENT_USER_REF.child("Event").child("Title").setValue(titleTextField.text)
        //        USER_REF.child(userID).child("newEvent").setValue(true)
        //        USER_REF.child(userID).child("Event").child("Title").setValue(titleTextField.text)
        //        USER_REF.child(userID).child("Event").child("Title").child(titleTextField.text!).setValue("2e")
        
        if(titleTextField.text != ""){
            print ("latitude \(Double((annotationLocation?.coordinate.latitude)!)), longitude: \(Double((annotationLocation?.coordinate.longitude)!))")
            let position = ["latitude": Double((annotationLocation?.coordinate.latitude)!), "longitude": Double((annotationLocation?.coordinate.longitude)!)] as [String: Double]
        let key = USER_REF.child(userID).child("posts").childByAutoId().key
            let posts = ["sender": String(CURRENT_USER_ID), "title": titleTextField.text!, "description": self.eventDescriptionView.text, "time": String(dateTime), "imageRef": self.drawingReference ?? "0", "soundRef": self.soundRef ?? "0", "position": position ] as [String : Any]
            
        let childUpdates = ["/\(userID)/Events/\(key)/": posts]
        USER_REF.updateChildValues(childUpdates)

        sendMessage(key: userID)
        }
        else {
            displayAlert(title: "Missing event-title", message: "You need to enter the name of your event")
        }
    }
    
    @IBAction func sendInviteButton(_ sender: UIButton) {
        uploadDrawnImage()
        popUpView.alpha = 0
        for friend in selectedFriends{
            sendInvite(userID: friend.id)
        }
        self.blurView.isHidden = true
    }
    
    
    //MARK: SET DATE AND TIME ON EVENT FUNCTIONS
    @IBAction func selectDateButton(_ sender: UIButton) {
        datePickerOutlet.isHidden = false
        viewBehindPickerWheels.isHidden = false
    }
    
    @IBAction func datePicker(_ sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: datePickerOutlet.date)
        let strTime = timeFormatter.string(from: datePickerOutlet.date)
        
        self.dateTime = "\(strDate)"
        self.timeTime = "\(strTime)"
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
        getAddress()
        
    }
    func getAddress(){
    
    }
    
    
    //MARK: ADD MICROPHONE SOUND
    
    @IBAction func microphoneButtonPressed(_ sender: UIButton) {
        recordingSession = AVAudioSession.sharedInstance()
        
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission{
                print ("accepted")
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
                
                print("recording:")
                print(filename)
                audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
                
                audioRecorder.delegate = self
                audioRecorder.record()
                audioRecorder.stop()
                SetSessionPlayerOn()
                audioRecorder.record()
                recordingButtonLabel.setTitle("Stop Recording", for: .normal)
            }
            catch{
                displayAlert(title: "Error", message: "Recording failed")
            }
        }
        else {
            audioRecorder.stop()
            SetSessionPlayerOff()
            audioRecorder = nil
            recordingButtonLabel.setTitle("Start recording", for: .normal)
            
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
            print(filename)
            audioPlayer = try AVAudioPlayer(contentsOf: filename)
            audioPlayer.play()
        }
        catch{
            print (error.localizedDescription)
        }
        
    }
    
    @IBAction func downloadSoundButton(_ sender: UIButton) {
        downloadSound(soundReference: "TBA")
    }
    
    func downloadSound(soundReference: String){
        
        let pathString = "storage"
        
        let downloadSoundRef = storageReference.child(soundReference)
        
        let fileUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        guard let fileUrl = fileUrls.first?.appendingPathComponent(pathString) else {
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
    
    @IBAction func uploadSoundButton(_ sender: UIButton) {
        uploadSound()
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
    
    //MARK: SELECT TYPE OF EVENT
    
    
    
    //MARK: OTHER FUNCTIONS
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if eventDescriptionView.textColor == UIColor.lightGray {
            eventDescriptionView.text = nil
            eventDescriptionView.textColor = UIColor.black
        }
    }
    
    func generateRandomNumber()->Int{
        let random = arc4random_uniform(1000000)
        return Int(random)
    }

    
    @IBAction func typeOfEventSelector(_ sender: UIButton) {
    }
    
    
}



















