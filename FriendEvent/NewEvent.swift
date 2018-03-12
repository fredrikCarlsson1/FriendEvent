//
//  NewEvent.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-09.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import MapKit

class NewEvent: UIViewController, MKMapViewDelegate  {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var searchOutlet: UIButton!

    @IBOutlet weak var popUpView: UIViewX!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popUpView.alpha = 0
        searchOutlet.layer.cornerRadius = 10
    }
    
    @IBAction func searcButton(_ sender: UIButton) {
        getSearchRequest()
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "annotation")
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
            view?.canShowCallout = true
            view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        } else {
            view?.annotation = annotation
        }
        return view
    }
    

    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control as? UIButton)?.buttonType ==   UIButtonType.detailDisclosure {
            pressed()
        }
        
    }
    
    func pressed() {
        popUpView.transform = CGAffineTransform(scaleX: 0.4, y: 1.8)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.popUpView.transform = .identity
        }) { (success) in
            
        }
        popUpView.alpha = 1
    }
    
    @IBAction func popUp(_ sender: UIButton) {
        pressed()
    }
    
    
    @IBAction func saveButton(_ sender: UIButton) {
        popUpView.alpha = 0
    }
    
    
}
