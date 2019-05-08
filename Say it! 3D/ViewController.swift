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
    
    var presetNum = 1
    
    @IBOutlet weak var fontButton: UIButton!
    @IBOutlet weak var countDownLabel: UILabel!
    
    let textAllowed = 20
    var textTimer = Timer()
    var currentFontFace = "Avenir-Black"
    var currentFontColor: UIColor = .white
    
    //Record Button
    @IBOutlet var recordButton: RecordButton!
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    @IBOutlet weak var recordView: UIView!
    
    var recorder: SceneKitVideoRecorder?
    
    @IBOutlet weak var textSizeButton: UIButton!

    //video url to pass
    var videoUrl: URL?
    
    //base size of animation
    var animSize: Float = 1.4
    
    //magnitude of animation
    var animMag: Float = 1.6
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    messageField.text = "Say it"

    UITextField.appearance().keyboardAppearance = .dark
    
    textSizeButton.adjustsImageWhenHighlighted = false
    fontButton.adjustsImageWhenHighlighted = false
    



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
    
    //messageField.text = "Say it"


    //hide textInputView on launch
    textInputView.isHidden = true
    

    
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
        
        //delay 0.3s
        
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
        stop()
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

        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let destVC = segue.destination as! ShareViewController
            destVC.videoUrl = self.videoUrl
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

    /////////////////record functions end/////////////////
    //////////////////////////////////////////////////////
    
    
    
    
    //////////////////////////////////////////////////////
    ////////////message input functions start/////////////
    
    func startTextInput(){
        
        textTimer.invalidate() // just in case this button is tapped multiple times
        
        // start the timer
        textTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(userIsTyping), userInfo: nil, repeats: true)
        
        textInputView.isHidden = false
        messageField.becomeFirstResponder()
        //hide auto suggestion
        //messageField.autocorrectionType = .no
        
        }
    
    //button to trigger text input view
    @IBAction func textInputButton(_ sender: Any) {
        startTextInput()
    }
    
    //tap to trigger text input view
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        guard sender.view != nil else { return }
        startTextInput()
    }
    
    @objc func userIsTyping(_ sender: Any) {
        countDownLabel.text = "\(textAllowed - messageField.text!.count)"
    }
    
    func submitText(){
        textTimer.invalidate()
        // Update new Node Options
        if messageField.text != "" {
            mouthOptions = [messageField.text as! String]
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            //faceNode.fontFace = currentFontFace
            faceNode.updateNewOptions(with: mouthOptions)}
        
        messageField.resignFirstResponder()
        textInputView.isHidden = true
    }
    
    //OK button to submit string
    @IBAction func handleSubmitButton(_ sender: Any) {
        submitText()
    }
    //tap gesture to submit string
    @IBAction func handleTapToSubmit(_ sender: Any) {
        submitText()
    }
    
    
    @IBAction func handleFontButton(_ sender: UIButton) {
        
        if(fontButton.titleLabel!.text == "REGULAR"){
            currentFontFace = "AvenirNext-HeavyItalic"
            messageField.font = UIFont(name: currentFontFace, size: 42)
            sender.setTitle("BOLD", for: .normal)
            fontButton.titleLabel?.font =  UIFont(name: currentFontFace, size: 13)
//            if (messageField.text != ""){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = currentFontFace
//            faceNode.updateNewOptions(with: mouthOptions)
//            }

        } else if (fontButton.titleLabel!.text == "BOLD"){
            currentFontFace = "Baskerville-SemiBold"
            messageField.font = UIFont(name: currentFontFace, size: 42)
            sender.setTitle("ELEGANT", for: .normal)
            fontButton.titleLabel?.font =  UIFont(name: currentFontFace, size: 13)
            

            
//            if (messageField.text != ""){
                let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
                faceNode.fontFace = currentFontFace
//            faceNode.updateNewOptions(with: mouthOptions)
//            }
            

        }else if (fontButton.titleLabel!.text == "ELEGANT"){
            currentFontFace = "Courier"
            messageField.font = UIFont(name: currentFontFace, size: 42)
            sender.setTitle("TYPEWRITTER", for: .normal)
            fontButton.titleLabel?.font =  UIFont(name: currentFontFace, size: 13)
            
//            if (messageField.text != ""){

            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = currentFontFace
//            faceNode.updateNewOptions(with: mouthOptions)
//            }
            
        }else if (fontButton.titleLabel!.text == "TYPEWRITTER"){
            currentFontFace = "Avenir-Black"
            messageField.font = UIFont(name: currentFontFace, size: 42)
            sender.setTitle("REGULAR", for: .normal)
            fontButton.titleLabel?.font =  UIFont(name: currentFontFace, size: 13)
//            if (messageField.text != ""){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = currentFontFace
//            faceNode.updateNewOptions(with: mouthOptions)
//            }
        }
        
    }

    @IBAction func handleWhiteButton(_ sender: Any) {
        messageField.textColor = .white
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.fontColor = .white
    }
    
    @IBAction func handleBlackButton(_ sender: Any) {
        messageField.textColor = .black
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.fontColor = .black
    }
    
    @IBAction func handleRedButton(_ sender: Any) {
        messageField.textColor = .red
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.fontColor = .red
    }
    
    
    @IBAction func handleYellowButton(_ sender: Any) {
        messageField.textColor = .yellow
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.fontColor = .yellow
    }
    
    
    @IBAction func handleSwipeLeft(_ sender: Any) {
        if (presetNum == 4) {
            presetNum = 1
        } else {
        presetNum += 1
        }
        updatePresets()
    }
    
    @IBAction func handleSwipeRight(_ sender: Any) {
        if (presetNum == 1) {
            presetNum = 4
        } else {
        presetNum -= 1
        }
        updatePresets()
    }
    
    //presets
    func updatePresets(){
        if (presetNum == 1){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "Avenir-Black"
            faceNode.fontColor = .white
            faceNode.updateNewOptions(with: mouthOptions)
            self.animSize = 1.4
            self.animMag = 1.6
            textSizeButton.setTitle("M", for: .normal)
            
        } else if (presetNum == 2){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "AvenirNext-HeavyItalic"
            faceNode.fontColor = UIColor(red: 255/255, green: 20/255, blue: 0/255, alpha: 1.0)
            faceNode.updateNewOptions(with: mouthOptions)
            self.animSize = 3.5
            self.animMag = 1.7
            textSizeButton.setTitle("L", for: .normal)
            
        } else if (presetNum == 3){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "Baskerville-SemiBold"
            faceNode.fontColor = UIColor(red: 236/255, green: 166/255, blue: 18/255, alpha: 1.0)
            faceNode.updateNewOptions(with: mouthOptions)
            self.animSize = 1.4
            self.animMag = 1.6
            textSizeButton.setTitle("M", for: .normal)
            
        } else if (presetNum == 4){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "Courier"
            faceNode.fontColor = UIColor(red: 255/255, green: 173/255, blue: 150/255, alpha: 1.0)
            faceNode.updateNewOptions(with: mouthOptions)
            self.animSize = 0.7
            self.animMag = 0.8
            textSizeButton.setTitle("S", for: .normal)
            
        }
    }
    
    @IBAction func HandleTextSizeButton(_ sender: UIButton) {
        
        if(textSizeButton.titleLabel!.text == "M"){
            
            self.animSize = 3.5
            self.animMag = 1.7

        sender.setTitle("L", for: .normal)
        } else if (textSizeButton.titleLabel!.text == "L"){

            self.animSize = 0.7
            self.animMag = 0.8

            sender.setTitle("S", for: .normal)
        }else if (textSizeButton.titleLabel!.text == "S"){

            self.animSize = 1.4
            self.animMag = 1.6

            sender.setTitle("M", for: .normal)
        }
    }
    

    
    
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
        child?.scale = SCNVector3(self.animSize + jawOpenValue*12*animMag, self.animSize/8 + jawOpenValue*2*animMag, 0.1)
      default:
        break
      }
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
//
//extension ViewController: RPPreviewViewControllerDelegate {
//    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
//        viewController.dismiss(animated: true)
//    }
//}

