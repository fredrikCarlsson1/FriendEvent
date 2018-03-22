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


class NewEvent: UIViewController, MKMapViewDelegate, UISearchBarDelegate, MessagingDelegate, UICollectionViewDelegate, UICollectionViewDataSource  {
    
    var imageReference: StorageReference{
        return Storage.storage().reference().child("images")
    }
    var downloadedImage = UIImageView()
    
    func uploadDrawnImage(){

            guard let image = sendImage.image else {return}
            guard let imageData = UIImageJPEGRepresentation(image, 1) else {return}
            
            let uploadRef = imageReference.child("newImage")
            
            let uploadTask = uploadRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                print("UPLOAD TASK FINISHED")
                print(metadata ?? "NO meta data")
                print(error ?? "NO error")
            })
            uploadTask.observe(.progress, handler: { (snapshot) in
                print(snapshot.progress)
            })
            uploadTask.resume()
    }
    
    func downloadImage(){
        let downloadImageRef = imageReference.child("newImage")
        
        let downloadTask = downloadImageRef.getData(maxSize: 1024*1024*15) { (data, error) in
            if let data = data {
                let image = UIImage(data: data)
                self.downloadedImage.image = image
            }
            print(error ?? "No ERROR")
        }
        downloadTask.resume()
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
    
    //MARK: MICROPHONE VARIBLES
    @IBOutlet weak var micView: UIView!
    
    
    //MARK: OTHER VARIBLES
    var totalTime: String?

    @IBOutlet weak var blurView: UIVisualEffectView!
    
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
                    if let time = totalTime{
                        cell1.dateLabel.text = time
                    }
                    return cell1
                case 1:
                    return collectionView.dequeueReusableCell(withReuseIdentifier: "cell3", for: indexPath)
                case 2:
                    return collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath)
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
        
        let title = "Quick Invite"
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
        
        let key = USER_REF.child(userID).child("posts").childByAutoId().key
        let post = ["uid": "2",
                    "author": "2",
                    "title": "2",
                    "body": "2"]
        let childUpdates = ["/\(userID)/Events/\(key)/": post]
        USER_REF.updateChildValues(childUpdates)
        sendMessage(key: userID)
    }
    
    @IBAction func sendInviteButton(_ sender: UIButton) {
        popUpView.alpha = 0
        for friend in selectedFriends{
            sendInvite(userID: friend.id)
        }
        uploadDrawnImage()
    }
    

    //MARK: SET DATE AND TIME ON EVENT FUNCTIONS
    @IBAction func selectDateButton(_ sender: UIButton) {
        datePickerOutlet.isHidden = false
    }

    @IBAction func datePicker(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        let timeFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
 
        let strDate = dateFormatter.string(from: datePickerOutlet.date)
        let strTime = timeFormatter.string(from: datePickerOutlet.date)
        totalTime = "\(strDate) \n \(strTime)"
        firstCollectionView.reloadData()
      
    }
    
    @IBOutlet weak var datePickerOutlet: UIDatePicker!
    
    
    //MARK: SET LOCATION IN POPUP
    
    @IBAction func locationButtonPressed(_ sender: UIButton) {
    }
    
    //MARK: ADD MICROPHONE SOUND
    
    @IBAction func microphoneButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.micView.transform = .identity
        }, completion: nil)
    }
    
    
    
    //MARK SELECT TYPE OF EVENT
    

    
    
}



















