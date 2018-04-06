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
    @IBOutlet weak var buttonOutlet: UIButton!
    @IBOutlet weak var usernameOutlet: UITextField!
    @IBOutlet weak var loginButtonOutlet: UIButtonX!
    @IBOutlet weak var signUpButtonOutlet: UIButtonX!
    @IBOutlet weak var facebookSignUpButtonOutlet: UIButtonX!
    @IBOutlet weak var forgotPasswordHaveAccountOutlet: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    //MARK: LoginButton - changes to Create user when SIGN UP button is pressed
    @IBAction func loginButton(_ sender: UIButton) {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        guard let latitude = AppDelegate.locationPlace?.latitude else {return}
        guard let longitude = AppDelegate.locationPlace?.longitude else {return}
        
        if (emailTextField.text != nil && passwordTextField.text != nil){
            if (loginButtonOutlet.titleLabel?.text == "Login"){ //Log in
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
                            self.alert(title: "Something went wrong", message: myError)
                            
                        }
                        else {
                            self.alert(title: "Something went wrong", message: "An error occurred")
                        }
                    }
                })
            }
            else{
                guard let username = usernameOutlet.text else {return}
                if username != "" {
                    Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                        if (user != nil){
                            guard let uid = user?.uid else {return}
                            let values = ["Email": email, "password": password, "fromDevice": AppDelegate.DEVICEID, "username": username] as [String : Any]
                            let ref = Database.database().reference().child("users").child(uid)
                            ref.updateChildValues(values)
                            self.alert(title: "Successfully registered!", message: "Welcome to Quick Inviter!")
                            
                            self.loginButtonOutlet.setTitle("Login", for: .normal)
                            self.signUpButtonOutlet.isHidden = false
                            self.facebookSignUpButtonOutlet.isHidden = false
                            self.usernameOutlet.isHidden = true
                        }
                        else{
                            if let myError = error?.localizedDescription{
                                self.alert(title: "Something went wrong", message: myError)
                            }
                            else {
                                self.alert(title: "Something went wrong", message: "An error occurred")
                            }
                        }
                    })
                }
                else {
                    self.alert(title: "Missing username", message: "You have to pick a username to complete the registration")
                }
            }
        }
    }
    
    //
    @IBAction func signUpButtonPressed(_ sender: UIButtonX) {
        
        usernameOutlet.isHidden = false
        loginButtonOutlet.setTitle("Create user", for: .normal)
        signUpButtonOutlet.isHidden = true
        facebookSignUpButtonOutlet.isHidden = true
        forgotPasswordHaveAccountOutlet.setTitle("I already have an account", for: .normal)
    }
    
    //MARK - TODO: send email to user?
    @IBAction func forgotPasswordAndAlreadyHaveAccountButton(_ sender: UIButton) {
        if (forgotPasswordHaveAccountOutlet.titleLabel?.text == "I already have an account"){
            loginButtonOutlet.setTitle("Login", for: .normal)
            usernameOutlet.isHidden = true
            signUpButtonOutlet.isHidden = false
            facebookSignUpButtonOutlet.isHidden = false
            forgotPasswordHaveAccountOutlet.setTitle("I forgot my password", for: .normal)
        }
        else {
            
        }
        
    }
    
}








