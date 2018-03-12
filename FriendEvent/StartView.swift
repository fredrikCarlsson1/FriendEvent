//
//  ViewController.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-05.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import MapKit

class StartView: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
 
    var pin:AddPin?

    @IBOutlet weak var mapView: MKMapView!
    var friendArray = [Friends]()
    let steve = Friends(name: "Steve", phoneNumber: "0120412", email: "feef@1.com")
    let george = Friends(name: "George", phoneNumber: "0120412", email: "feef@1.com")

    override func viewDidLoad() {
        super.viewDidLoad()
       
        friendArray.append(steve)
        friendArray.append(george)
        navigationController?.navigationBar.dropShadow()
        
        mapView.delegate = self
        mapView.dropShadow()
        
        self.mapView.setUserTrackingMode(.follow, animated: true)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        mapView.addGestureRecognizer(gestureRecognizer)
        
        

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
        return friendArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = friendArray[indexPath.row].name
        return cell
    }
    
    @IBAction func newEventSegue(_ sender: UIButton) {
        performSegue(withIdentifier: "newEventSegue", sender: self)
    }
    


}

