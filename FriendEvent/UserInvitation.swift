//
//  UserInvitation.swift
//  FriendEvent
//
//  Created by Fredrik Carlsson on 2018-03-23.
//  Copyright © 2018 Fredrik Carlsson. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase


class UserInvitation: UIViewController {
    var storageReference: StorageReference{
        return Storage.storage().reference().child("images")
    }
    //MARK: AUDIO VARIBLES
        var player: AVAudioPlayer?
    
    //MARK: DRAWING VARIBLES
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: AUDIO FUNCTIONS
    @IBAction func downloadSoundButton(_ sender: UIButton) {
        downloadSound()
    }

    func downloadSound(){
        
        let pathString = "newImage"
        let downloadImageRef = storageReference.child("newImage")
        
        let fileUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        guard let fileUrl = fileUrls.first?.appendingPathComponent(pathString) else {
            return
        }
        
        let downloadTask = downloadImageRef.write(toFile: fileUrl)
        
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
    
    
    
    //MARK: DRAWING FUNCTIONS
    
    


}
