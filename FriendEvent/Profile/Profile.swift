//
//  Profile.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-04-09.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase


class Profile: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var newPasswordView: UIView!
    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var closeNewPasswordViewOutlet: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    let USER_REF = Database.database().reference().child("users")
    
    var CURRENT_USER_REF: DatabaseReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.child("\(id)")
    }
    
    var CURRENT_USER_EMAIL: String {
        let email = Auth.auth().currentUser!.email
        return email!
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.newPasswordView.transform = CGAffineTransform(scaleX: 1, y:0.0)
        self.usernameView.transform = CGAffineTransform(scaleX: 1, y:0.0)
        self.hideKeyboardWhenTappedAround()
    }
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emailCell", for: indexPath) as! emailCell
            cell.userEmailLabel.text = CURRENT_USER_EMAIL
            
            return cell
        }
        else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath) as! nameCell
            let _ = CURRENT_USER_REF.observeSingleEvent(of: .value, with: { (snapshow) in
                
                cell.usernameButtonOutlet.setTitle(snapshow.childSnapshot(forPath: "username").value as? String, for: .normal)
            })
            return cell
        }
        else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "passwordCell", for: indexPath) as! passwordCell
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "showLocationCell", for: indexPath) as! ShowPositionCell
            
            if CLLocationManager.locationServicesEnabled(){
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    CURRENT_USER_REF.child("showPosition").setValue(false)
                    
                    cell.showPositionSwitch.isOn = false
                case .authorizedAlways, .authorizedWhenInUse:
                    CURRENT_USER_REF.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        let showMyPosition = snapshot.childSnapshot(forPath: "showPosition").value as! Bool
                        
                        if showMyPosition == true {
                            cell.showPositionSwitch.isOn = true
                        }
                        else {
                            cell.showPositionSwitch.isOn = false
                        }
                        
                    })
                    
                }
            }
            else {
                print("no background updates")
            }
            return cell
        }
    }
    
    
    //MARK: CHANGE PASSWORD
    @IBAction func passwordButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.newPasswordView.transform = .identity
        }, completion: nil)
        
        self.closeNewPasswordViewOutlet.isHidden = false
    }
    
    typealias Completion = (Error?) -> Void
    
    func changePassword(email: String, currentPassword: String, newPassword: String, completion: @escaping Completion) {
        let currentUser = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (error) in
            if error == nil {
                currentUser?.updatePassword(to: newPassword) { (errror) in
                    completion(errror)
                }
            } else {
                completion(error)
            }
        })
    }
    
    @IBAction func changePasswordButton(_ sender: UIButton) {
        self.closeNewPasswordViewOutlet.isHidden = false
        if let oldPassword = oldPasswordTextField.text {
            if let newPassword = newPasswordTextField.text{
                self.changePassword(email: CURRENT_USER_EMAIL, currentPassword: oldPassword, newPassword: newPassword)
                { (error) in
                    if error == nil {
                        self.alert(title: "Password updated" , message: "Your password has been changed")
                    }else {
                        
                        self.alert(title: "Something went wrong", message: "Make sure your old password is correct and the new contains at least six characters")
                    }
                }
            }
            self.minimizePasswordAndUsernameView()
        }
        else {
            alert(title: "Missing information", message: "You need to fill in your previous- and your new password")
        }
        
    }
    
    //Closes the views for changing password and username
    func minimizePasswordAndUsernameView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            self.usernameView.transform = CGAffineTransform.init(scaleX: 1, y: 0)
            self.newPasswordView.transform = CGAffineTransform.init(scaleX: 1, y: 0)
        }, completion: nil)
        self.closeNewPasswordViewOutlet.isHidden = true
    }
    
    @IBAction func closeNewPasswordViewButton(_ sender: UIButton) {
        self.minimizePasswordAndUsernameView()
        
    }
    
    
    //MARK: CHANGE USERNAME
    @IBAction func showChangeUsernameView(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn], animations: {
            
            self.usernameView.transform = .identity
        }, completion: nil)
        self.closeNewPasswordViewOutlet.isHidden = false
    }
    
    @IBAction func changeUsernameButton(_ sender: UIButton) {
        if let userName = usernameTextField.text { CURRENT_USER_REF.updateChildValues(["username" : userName])
        }
        self.minimizePasswordAndUsernameView()
        
        tableView.reloadData()
    }
    
    
    //MARK: SWITCH FOR SHOWING POSITION
    @IBAction func showMyLocationSwitch(_ sender: UISwitch) {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            let alert = UIAlertController(title: "Need Authorization", message: "You need to allow the app use your location in order for your friends to get your position", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                let url = URL(string: UIApplicationOpenSettingsURLString)!
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
        
        if sender.isOn{
            CURRENT_USER_REF.child("showPosition").setValue(true)
            AppDelegate.showPosition = true
        }
        else {
            CURRENT_USER_REF.child("showPosition").setValue(false)
            CURRENT_USER_REF.child("longitude").setValue(0)
            CURRENT_USER_REF.child("latitude").setValue(0)
            AppDelegate.showPosition = false
        }
    }
    
    
    //MARK: SIGN OUT FROM ACCOUNT
    @IBAction func signOutButton(_ sender: UIButton) {
        self.logoutAccount()
        performSegue(withIdentifier: "logOutSegue", sender: self)
        
    }
    
    /** Logs out an account */
    func logoutAccount() {
        try! Auth.auth().signOut()
        print("signed out")
    }
    
    
    
}











