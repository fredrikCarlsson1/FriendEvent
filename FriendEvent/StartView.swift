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
    var dbReference: DatabaseReference?
    var dbHandler: DatabaseHandle?
    
    @IBOutlet weak var tableView: UITableView!
    
    
 
    var pin:AddPin?

    @IBOutlet weak var mapView: MKMapView!
    var friendList = [User]()
    
    
    let USER_REF = Database.database().reference().child("users")
    
    /** The Firebase reference to the current user tree */
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    /** The Firebase reference to the current user's friend tree */
    var CURRENT_USER_FRIENDS_REF: DatabaseReference {
        return CURRENT_USER_REF.child("friends")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()      
        dbReference = Database.database().reference()
        
        addFriendObserver()


        //retrive data
//        dbHandler = dbReference?.child("name").observe(.childAdded, with: { (snapshot) in
//             let name:String = (snapshot.value as? String)!
//            print(name)
//        })
//        fetchUsers()
       

        navigationController?.navigationBar.dropShadow()
        
        mapView.delegate = self
        mapView.dropShadow()
        
        self.mapView.setUserTrackingMode(.follow, animated: true)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        mapView.addGestureRecognizer(gestureRecognizer)

    }
    /** The list of all friends of the current user. */
    
    /** Adds a friend observer. The completion function will run every time this list changes, allowing you
     to update your UI. */
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
    
    /** Gets the User object for the specified user id */
    func getUser(_ userID: String, completion: @escaping (User) -> Void) {
        USER_REF.child(userID).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let email = snapshot.childSnapshot(forPath: "Email").value as! String
            let id = snapshot.key
            completion(User(email: email, userID: id))
        })
    }

    
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = friendList[indexPath.row].email
        return cell
    }
    
//    func fetchUsers(){
//        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
//            let email = snapshot.childSnapshot(forPath: "Email")
//            let friend = Friends()
//            friend.email = email.value as? String
//            self.userList.append(user)
//
//            self.tableView.reloadData()
//
//        }, withCancel: nil)
//    }
    
    
    @IBAction func newEventSegue(_ sender: UIButton) {
        performSegue(withIdentifier: "newEventSegue", sender: self)
    }
    


}

