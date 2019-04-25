import UIKit
import ARKit
import ReplayKit
import RecordButton
import SceneKit
import SceneKitVideoRecorder
import Photos

class ViewController: UIViewController{
    @IBOutlet var sceneView: ARSCNView!
    weak var viewController: UIViewController!

    @IBOutlet weak var textInputView: UIView!
    
    @IBOutlet weak var messageField: UITextField!
    var mouthOptions = ["Say it"]

    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    
    //Record Button
    @IBOutlet var recordButton: RecordButton!
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    @IBOutlet weak var recordView: UIView!
    
    var recorder: SceneKitVideoRecorder?
    
    //video url to pass
    var videoUrl: URL?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    UITextField.appearance().keyboardAppearance = .dark

    // set up recorder button
    recordButton.center = recordView.center
    recordButton.progressColor = .white
    recordButton.closeWhenFinished = false
    recordButton.addTarget(self, action: #selector(ViewController.record), for: .touchDown)
    recordButton.addTarget(self, action: #selector(ViewController.stop), for: UIControl.Event.touchUpInside)
    recordButton.center.x = recordView.center.x
    recordButton.center.y = recordView.center.y
    
    //set up Scene Kit View Recorder to record ARSceneView
    recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView)

    

    //hide textInputView on launch
    textInputView.isHidden = true
    
    //show recordView on launch
    recordView.isHidden = false
    
    guard ARFaceTrackingConfiguration.isSupported else { fatalError() }
    sceneView.delegate = self
  }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //initiate AR tracking
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //set status bar to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    
    
    
    
    //////////////////////////////////////////////////////
    ////////////////record functions start////////////////

    //record button func
    @objc func record() {
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.updateProgress), userInfo: nil, repeats: true)
        
        //Scene kit video recorder
        self.recorder?.startWriting().onSuccess {
            print("Recording Started")
        }
    }

    @objc func updateProgress() {

        let maxDuration = CGFloat(5) // Max duration of the recordButton

        progress = progress + (CGFloat(0.05) / maxDuration)
        recordButton.setProgress(progress)

        if progress >= 1 {
            progressTimer.invalidate()
        }

    }

    @objc func stop() {
        
        //Record Button
        self.progressTimer.invalidate()
        progress = 0
        
        //Scene kit video recorder
        self.recorder?.finishWriting().onSuccess { [weak self] url in
            print("Recording Finished", url)
            self?.videoUrl = url
            self?.performSegue(withIdentifier: "toShare", sender: self)

            //self?.checkAuthorizationAndPresentActivityController(toShare: url, using: self!)
        }
    
    }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let destVC = segue.destination as! ShareViewController
            destVC.videoUrl = self.videoUrl
            
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
    

    
    //Replay Kit process recording
    
    func handleRecordStart(){
        let recorder = RPScreenRecorder.shared()
            recorder.startRecording { (error) in
                guard error == nil else {
                    print("Failed to start recording")
                    return}
        }
        
    }
    
    func handleRecordEnd(){
        let recorder = RPScreenRecorder.shared()

        recorder.stopRecording { (previewController, error) in
            guard error == nil else {
                print("Failed to stop recording")
                return
            }
        previewController?.previewControllerDelegate = self
        self.viewController.present(previewController!, animated: true)
        }
        recordView.isHidden = true
    }
    
    //scene kit video recorder
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if recorder == nil {
            var options = SceneKitVideoRecorder.Options.default
            
            let scale = UIScreen.main.nativeScale
            let sceneSize = sceneView.bounds.size
            options.videoSize = CGSize(width: sceneSize.width * scale, height: sceneSize.height * scale)
            recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView, options: options)
        }
    }
    
    @IBAction func startRecording (sender: UIButton) {
        self.recorder?.startWriting().onSuccess {
            print("Recording Started")
        }
    }
    
    @IBAction func stopRecording (sender: UIButton) {
        self.recorder?.finishWriting().onSuccess { [weak self] url in
            print("Recording Finished", url)
        }
    }
    /////////////////record functions end/////////////////
    //////////////////////////////////////////////////////
    
    
    
    
    //////////////////////////////////////////////////////
    ////////////message input functions start/////////////
    
    //button to trigger text input view
    @IBAction func textInputButton(_ sender: Any) {
        textInputView.isHidden = false
        messageField.becomeFirstResponder()
    }
    
    //Done button to submit string into mouthOptions
    @IBAction func submitButton(_ sender: Any) {
        
        //add text field input to array
        //mouthOptions.insert(messageField.text as! String, at: 0)
        mouthOptions = [messageField.text as! String]
        
        // Update new Node Options
        if messageField.text != "" {
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.updateNewOptions(with: mouthOptions)}
        //
        //show updated array
        //messageResult.text = mouthOptions.joined(separator:" - ")
        messageField.text = ""
        messageField.resignFirstResponder()
        textInputView.isHidden = true
        
    }
    //touch outside the message field to dismiss keyboard
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        messageField.resignFirstResponder()
//    }
    
    /////////////message input functions end//////////////
    //////////////////////////////////////////////////////
    
    
    
    
    //////////////////////////////////////////////////////
    //////////////////AR functions start//////////////////

  //use FaceNode.swift to map facial features, and animate on jaw open
  func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
    for (feature, indices) in zip(features, featureIndices) {
      let child = node.childNode(withName: feature, recursively: false) as? FaceNode
      let vertices = indices.map { anchor.geometry.vertices[$0] }
      child?.updatePosition(for: vertices)
      
      switch feature {
      case "mouth":
        let jawOpenValue = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.2
        child?.scale = SCNVector3(1 + jawOpenValue*6, 0.1 + jawOpenValue*2, 0.1)
      default:
        break
      }
    }
  }
    
  //enable switching 
  @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: sceneView)
    let results = sceneView.hitTest(location, options: nil)
    if let result = results.first,
      let node = result.node as? FaceNode {
      node.next()
    }
  }
    
}
///////////////////AR functions end///////////////////
//////////////////////////////////////////////////////

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}



    

    
    
    




extension ViewController: ARSCNViewDelegate {
  
  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    guard let faceAnchor = anchor as? ARFaceAnchor,
          let device = sceneView.device else { return nil }
    let faceGeometry = ARSCNFaceGeometry(device: device)
    let node = SCNNode(geometry: faceGeometry)
    node.geometry?.firstMaterial?.fillMode = .lines
    node.geometry?.firstMaterial?.transparency = 0.0
    
    
    let mouthNode = FaceNode(with: mouthOptions)
    mouthNode.name = "mouth"
    node.addChildNode(mouthNode)
    
    
    updateFeatures(for: node, using: faceAnchor)
    return node
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }
    
    faceGeometry.update(from: faceAnchor.geometry)
    updateFeatures(for: node, using: faceAnchor)
  }
}

extension ViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        viewController.dismiss(animated: true)
    }
}

