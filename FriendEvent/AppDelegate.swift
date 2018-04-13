//
//  AppDelegate.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-05.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import Firebase
import FirebaseMessaging
import FirebaseInstanceID
import UserNotifications
import MapKit
import FBSDKCoreKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    var locationManager = CLLocationManager()
    static var locationPlace: CLLocationCoordinate2D?
    
    //MARK: VARIBLES TO SEND NOTIFICATIONS
    static let NOTIFICATION_URL = "https://gcm-http.googleapis.com/gcm/send"
    static var DEVICEID = String()
    static let SERVERKEY = "AAAAz7Aias4:APA91bHd16tDokkhAGfv1wDozUOf91FLcNY5IaAm8iUcPfS0giVqYoKZ25mZySMTboKfODYt4paapm1W6I-IrlAhbDwrdPspscLpyRq01vW0j6nrpORQSxrHwDQO6hHREan7DxgT0CNU"
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        // Ask for userlocation allways/when in use/never
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        
        FirebaseApp.configure()
        
        //Notofications
        if #available (iOS 10.0, *){
            UNUserNotificationCenter.current().delegate = self
            let option: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: option, completionHandler: { (bool, err) in
            })
        }
        else{
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        //Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        
        return true
    }
    
    //Facebook
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        
        return handled
    }
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    //Get user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        AppDelegate.locationPlace = location.coordinate
        
        ////////// Code to update location
        
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        self.latitude = locValue.latitude
        self.longitude = locValue.longitude
        
        
        
        //////////
        
    }
    
    
    // FOR SINGLE DEVICE MESSAGE
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        // print("Firebase registration token: \(fcmToken)")
        guard let newToken = InstanceID.instanceID().token() else {return}
        AppDelegate.DEVICEID = newToken
        connectToFCM()
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notification = response.notification.request.content.body
        
        print(notification)
        completionHandler()
        
    }
    
    var timer = Timer()
    
    
    
    
    //Runs when moved out from app
    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
        
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
                print("hej")
                timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(AppDelegate.updatePositionInBackground), userInfo: nil, repeats: true)
                doBackgroundTask()
            }
        }
        else {
            print("no background updates")
        }
    }
    
    @objc func updatePositionInBackground(){
        print("updatePositionInBackground!!!")
        
        guard let latitude = AppDelegate.locationPlace?.latitude else {return}
        guard let longitude = AppDelegate.locationPlace?.longitude else {return}
        
        let id = Auth.auth().currentUser?.uid
        
        let USER_REF = Database.database().reference().child("users")
        
        USER_REF.observeSingleEvent(of: .value, with: { (snapshot) in
            if let id = id{
                if snapshot.hasChild(id){
                    
                    var CURRENT_USER_REF: DatabaseReference {
                        let id = Auth.auth().currentUser!.uid
                        return USER_REF.child("\(id)")
                    }
                    let values = ["latitude": latitude, "longitude": longitude] as [String : Any]
                    
                    CURRENT_USER_REF.updateChildValues(values)
                }
            }else{
                print("user dosnt exist")
            }
            
        })
        
    }
    
    func doBackgroundTask() {
        DispatchQueue.main.async {
            self.beginBackgroundUpdateTask()
            print("DO background task")
        }
    }
    
    func beginBackgroundUpdateTask() {
        
        UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(AppDelegate.updatePositionInBackground), userInfo: nil, repeats: true)
            print("beginBackgroundUpdateTask1")
        })
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let token = InstanceID.instanceID().token() else {return}
        
        AppDelegate.DEVICEID = token
        connectToFCM()
    }
    
    func connectToFCM(){
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }
    
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "FriendEvent")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    //    func FBHandler(){
    //        Messaging.messaging().shouldEstablishDirectChannel = true
    //
    //    }
    //
    //    @objc func refreshToken(notification: NSNotification){
    //        let refreshToken = InstanceID.instanceID().token()!
    //        print("***\(refreshToken)***")
    //
    //        FBHandler()
    //    }
    
}

