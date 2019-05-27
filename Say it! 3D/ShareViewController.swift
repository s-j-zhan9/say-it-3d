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
    var playerLayer: AVPlayerLayer!
    var savedChecker: Bool = false

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var sharePanel: UIView!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var closeInfoButton: UIButton!
    @IBOutlet weak var downloadBGView: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    
    //download button
    @IBOutlet weak var downloadArrow: UIImageView!
    @IBOutlet weak var savedLabel: UILabel!
    
    
    
    var  player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, policy: .default, options: .defaultToSpeaker)
        
        //infoButton.isHidden = false
        infoView.isHidden = true
        downloadBGView.isHidden = true
        
//        sharePanel.layer.shadowColor = UIColor.black.cgColor
//        sharePanel.layer.shadowOpacity = 0.2
//        sharePanel.layer.shadowOffset = CGSize(width: 0, height: 0)
//        sharePanel.layer.shadowRadius = 2
        
        if videoUrl != nil {
            print("video url passed to shareview is:\(String(describing: videoUrl))")
            loopVideo()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    

    private func loopVideo() {

        
        self.player = AVPlayer(url: self.videoUrl!)
        let playerLayer = AVPlayerLayer(player: player)
        
        //set up player layer
        playerLayer.frame = CGRect(x: 0,y: 0,width: self.playView.frame.width, height: self.playView.frame.height)
        //playerLayer.position = self.view.center
        playerLayer.position = CGPoint(x: self.playView.bounds.midX, y: self.playView.bounds.midY)
        
        //player styling
        playerLayer.shadowColor = UIColor.black.cgColor
        playerLayer.shadowOpacity = 0.3
        playerLayer.shadowOffset = CGSize(width: 0, height: 1)
        playerLayer.shadowRadius = -4

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: self.player!.currentItem,
                                               queue: nil) { [weak self] note in
                                                self?.player!.seek(to: CMTime.zero)
                                                self?.player!.play()
        }

        self.playView.layer.addSublayer(playerLayer)
        player!.volume = 1.0
        player!.play()
    }
    
    @IBAction func handleCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func handleIgButton(_ sender: Any) {
        
        let url = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(url){
            
            let backgroundData = NSData(contentsOf: videoUrl)
            let pasteBoardItems = [
                ["com.instagram.sharedSticker.backgroundVideo" : backgroundData]
            ]
            
            if #available(iOS 10.0, *) {
                
                UIPasteboard.general.setItems(pasteBoardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
            } else {
                UIPasteboard.general.items = pasteBoardItems
            }
            UIApplication.shared.openURL(url)
    }
    }
    
    
    @IBAction func handleSaveButton(_ sender: Any) {
        print("save button clicked")
        self.checkAuthorizationAndSaveToCameraRoll(toShare: videoUrl, using: self)
        downloadFeedback()
        
    }
    
    //save directly to camera roll
    private func checkAuthorizationAndSaveToCameraRoll(toShare data: URL, using presenter: UIViewController) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            self.savedChecker = true
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: data)
            }) { saved, error in
                if saved {
                    
                }
            }
            
            
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
    
    
    
    func downloadFeedback(){
        
        if(self.savedChecker == true){
            

            self.downloadBGView.alpha = 0.0

            self.downloadBGView.isHidden = false
            self.savedLabel.alpha = 0

 
            UIView.animate(
                withDuration: 0.3,
                delay: 0.6,
                animations: {
                    self.downloadBGView.alpha = 1
            })
            
            UIView.animate(
                withDuration: 0.2,
                delay: 1.6,
                options: [.curveLinear, ],
                animations: {
                    self.downloadBGView.alpha = 0
            })
            
            UIView.animate(
                withDuration: 0.2,
                delay: 0.4,
                options: [.curveLinear,],
                animations: {
                    self.savedLabel.alpha = 1
            })
            
            UIView.animate(
                withDuration: 0.5,
                delay: 0.2,
                options: [.curveLinear, ],
                animations: {
                    self.downloadArrow.center = CGPoint(x: self.downloadArrow.center.x, y: self.downloadArrow.center.y+25)
            })
            
            self.downloadArrow.center.y = self.downloadArrow.center.y
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                self.downloadArrow.center.y = self.downloadArrow.center.y-25
                self.downloadBGView.isHidden = true
            }
            
        }
        //        let alertController = UIAlertController(title: "Saved to Photo", message: nil, preferredStyle: .alert)
        //        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        //        alertController.addAction(defaultAction)
        //        self.present(alertController, animated: true, completion: nil)
    }

    
    @IBAction func handleShareButton(_ sender: Any) {
        print("share button clicked")
        self.checkAuthorizationAndPresentActivityController(toShare: videoUrl as Any, using: self)
    }
    
    //Sharesheet & access to photo lib
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

    @IBAction func openLink(_ sender: Any) {
        guard let url = URL(string: "https://www.s-j-zhang.com") else { return }
        UIApplication.shared.open(url)
    }
    

    


    @IBAction func handleInfoButton(_ sender: Any) {
        infoButton.isHidden = true
        infoView.isHidden = false
        sharePanel.isHidden = true
        closeButton.isHidden = true
        
    }
    
    @IBAction func handleCloseInfoButton(_ sender: Any) {
        infoButton.isHidden = false
        infoView.isHidden = true
        closeButton.isHidden = false
        sharePanel.isHidden = false
    }
}
