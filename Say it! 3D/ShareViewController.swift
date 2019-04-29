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
    @IBOutlet weak var sharePanel: UIView!
    @IBOutlet weak var playView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharePanel.layer.shadowColor = UIColor.black.cgColor
        sharePanel.layer.shadowOpacity = 0.2
        sharePanel.layer.shadowOffset = CGSize(width: 0, height: 0)
        sharePanel.layer.shadowRadius = 2
        
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
    
    private func loopVideo2() {
        let player = AVPlayer(url: self.videoUrl!)
        let playerLayer = AVPlayerLayer(player: player)
        //set up player layer
        playerLayer.frame = CGRect(x: 0,y: 0,width: self.view.frame.width * 0.98,height: self.view.frame.height * 0.98)
        //playerLayer.position = self.view.center
        playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        
        playerLayer.shadowColor = UIColor.black.cgColor
        playerLayer.shadowOpacity = 1
        playerLayer.shadowOffset = CGSize.zero
        playerLayer.shadowRadius = 10

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: nil,
                                               queue: nil) { [weak self] note in
                                                player.seek(to: CMTime.zero)
                                                player.play()
        }
        
//        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
//            player.seek(to: CMTime.zero)
//            player.play()
//            }
        self.view.layer.addSublayer(playerLayer)
        }
    
    private func loopVideo() {
        let asset = AVAsset(url: self.videoUrl)
        let playerItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        // Begin looping playback
        queuePlayer.play()
        playerLayer = AVPlayerLayer(player: queuePlayer)

        // Create a new player looper with the queue player and template item
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        //set up player layer
        playerLayer.frame = CGRect(x: 0,y: 0,width: self.playView.frame.width, height: self.playView.frame.height)
        //playerLayer.position = self.view.center
        playerLayer.position = CGPoint(x: self.playView.bounds.midX, y: self.playView.bounds.midY)
        
        playerLayer.shadowColor = UIColor.black.cgColor
        playerLayer.shadowOpacity = 0.1
        playerLayer.shadowOffset = CGSize(width: 0, height: 1)
        playerLayer.shadowRadius = 2
        self.playView.layer.addSublayer(playerLayer)

        print("playerLayer created")
        
        
    }
    
    @IBAction func handleCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
    
    
    @IBAction func handleIgButton(_ sender: Any) {
        
        
        print("ig button clicked")

    }
    
    //send to instagram: https://developers.facebook.com/docs/instagram/sharing-to-stories/
//    - (void)shareBackgroundImage {
//    [self backgroundImage:UIImagePNGRepresentation([UIImage imageNamed:@"backgroundImage"])
//    attributionURL:@"http://your-deep-link-url"];
//    }
//
//    - (void)backgroundImage:(NSData *)backgroundImage
//    attributionURL:(NSString *)attributionURL {
//
//    // Verify app can open custom URL scheme, open if able
//    NSURL *urlScheme = [NSURL URLWithString:@"instagram-stories://share"];
//    if ([[UIApplication sharedApplication] canOpenURL:urlScheme]) {
//
//    // Assign background image asset and attribution link URL to pasteboard
//    NSArray *pasteboardItems = @[@{@"com.instagram.sharedSticker.backgroundImage" : backgroundImage,
//    @"com.instagram.sharedSticker.contentURL" : attributionURL}];
//    NSDictionary *pasteboardOptions = @{UIPasteboardOptionExpirationDate : [[NSDate date] dateByAddingTimeInterval:60 * 5]};
//    // This call is iOS 10+, can use 'setItems' depending on what versions you support
//    [[UIPasteboard generalPasteboard] setItems:pasteboardItems options:pasteboardOptions];
//
//    [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:nil];
//    } else {
//    // Handle older app versions or app not installed case
//    }
//    }
    
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
