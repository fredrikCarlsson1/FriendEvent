//
//  LogIn.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-13.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase


class LogIn: UIViewController {
    
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var segmentControll: UISegmentedControl!
    @IBOutlet weak var buttonOutlet: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButton(_ sender: UIButton) {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        guard let latitude = AppDelegate.locationPlace?.latitude else {return}
        guard let longitude = AppDelegate.locationPlace?.longitude else {return}
        
        
        
        if (emailTextField.text != nil && passwordTextField.text != nil){
            if (segmentControll.selectedSegmentIndex == 0){ //Log in
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    if (user != nil){
                        guard let uid = user?.uid else {return}
                        let values = ["Email": email, "password": password, "fromDevice": AppDelegate.DEVICEID, "latitude": latitude, "longitude": longitude] as [String : Any]
                        let ref = Database.database().reference().child("users").child(uid)
                        
                        ref.updateChildValues(values)
                        self.performSegue(withIdentifier: "loginSegue", sender: self)
                    }
                    else{
                        if let myError = error?.localizedDescription{
                            print (myError)
                        }
                        else {
                            print("ERROR!")
                        }
                    }
                })
            }
            else { //sign up user
           
                
                Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                    if (user != nil){
                        guard let uid = user?.uid else {return}
                        let values = ["Email": email, "password": password, "fromDevice": AppDelegate.DEVICEID] as [String : Any]
                        let ref = Database.database().reference().child("users").child(uid)
                        
                        ref.updateChildValues(values)
                        print("Successfully registered!")
                        
                        
                    
                    }
                    else{
                        if let myError = error?.localizedDescription{
                            print (myError)
                        }
                        else {
                            print("ERROR!")
                        }
                    }
                })
            }
        }
    }
    
    

}
