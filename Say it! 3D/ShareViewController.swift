//
//  ShareViewController.swift
//  Say it! 3D
//
//  Created by S. J. Zhang on 4/24/19.
//  Copyright © 2019 s-j-zhang. All rights reserved.
//

import UIKit
import ARKit
import ReplayKit
import RecordButton
import SceneKit
import SceneKitVideoRecorder
import Photos
import AVKit
import AVFoundation

class ShareViewController: UIViewController {
    
    var videoUrl : URL!
    var playerLooper: AVPlayerLooper!

    override func viewDidLoad() {
        super.viewDidLoad()
        if videoUrl != nil {
            print("printing url from shareview:\(String(describing: videoUrl))")}
        loopVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func playVideo() {
        let player = AVPlayer(url: self.videoUrl!)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0,y: 0,width: self.view.frame.width * 0.65,height: self.view.frame.height * 0.65)
        playerLayer.position = self.view.center
        self.view.layer.addSublayer(playerLayer)
        player.play()
    }
    
    private func loopVideo() {
        let asset = AVAsset(url: self.videoUrl)
        let playerItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        // Create a new player looper with the queue player and template item
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
    
        
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.frame = CGRect(x: 0,y: 0,width: self.view.frame.width * 0.65,height: self.view.frame.height * 0.65)
        playerLayer.position = self.view.center
        self.view.layer.addSublayer(playerLayer)
        
        // Begin looping playback
        queuePlayer.play()
    }
    
    @IBAction func handleCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
    
    
    @IBAction func handleIgButton(_ sender: Any) {
        print("ig button clicked")

    }
    
    @IBAction func handleSaveButton(_ sender: Any) {
        
        print("save button clicked")
        self.checkAuthorizationAndPresentActivityController(toShare: videoUrl, using: self)
    }
    @IBAction func handleShareButton(_ sender: Any) {
        print("share button clicked")
        self.checkAuthorizationAndPresentActivityController(toShare: videoUrl, using: self)
    }
    //Sharesheet & acess to photo lib
    private func checkAuthorizationAndPresentActivityController(toShare data: Any, using presenter: UIViewController) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]
            presenter.present(activityViewController, animated: true, completion: nil)
        case .restricted, .denied:
            let libraryRestrictedAlert = UIAlertController(title: "Photos access denied",
                                                           message: "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots.",
                                                           preferredStyle: UIAlertController.Style.alert)
            libraryRestrictedAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            presenter.present(libraryRestrictedAlert, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                    activityViewController.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]
                    presenter.present(activityViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
