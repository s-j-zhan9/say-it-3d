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
    
    //text size
    @IBOutlet weak var textSizeButton: UIButton!
    var textSizeState = 2
    
    //video url to pass
    var videoUrl: URL?
    
    //base size of animation
    var animSize: Float = 1.3
    
    //magnitude of animation
    var animMag: Float = 1.5
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    UITextField.appearance().keyboardAppearance = .dark
    
    textSizeButton.adjustsImageWhenHighlighted = false

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
    
    messageField.text = "Say it"


    //hide textInputView on launch
    textInputView.isHidden = true
    
    //show recordView on launch
    //recordView.isHidden = false
    
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.recorder?.startWriting().onSuccess {
                print("Recording Started")
            }
        })
        
        //Scene kit video recorder (working)
        
//        self.recorder?.startWriting().onSuccess {
//            print("Recording Started")
//        }
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
        textInputView.isHidden = false
        messageField.becomeFirstResponder()
        //hide auto suggestion
        messageField.autocorrectionType = .no
    }
    
    //button to trigger text input view
    @IBAction func textInputButton(_ sender: Any) {
        startTextInput()
    }
    
    //tap to trigger text input view
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        //    let location = sender.location(in: sceneView)
        //    let results = sceneView.hitTest(location, options: nil)
        //    if let result = results.first,
        //      let node = result.node as? FaceNode {
        //      node.next()
        //    }
        guard sender.view != nil else { return }
        startTextInput()
    }
    
    func submitText(){
        //add text field input to array
        //mouthOptions.insert(messageField.text as! String, at: 0)
        
        // Update new Node Options
        if messageField.text != "" {
            mouthOptions = [messageField.text as! String]
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.updateNewOptions(with: mouthOptions)}
        
        messageField.resignFirstResponder()
        textInputView.isHidden = true
    }
    
    //OK button to submit string into mouthOptions
    @IBAction func handleSubmitButton(_ sender: Any) {
        submitText()
    }
    //tap gesture to submit string
    @IBAction func handleTapToSubmit(_ sender: Any) {
        submitText()
    }
    
    func changeTextToLarge(){
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        
        messageField.font = UIFont(name: "Verdana", size: 20)
        var bgSize = CGSize(width: messageField.bounds.height, height: messageField.bounds.height)
        faceNode.bgSize = bgSize
        faceNode.fontFace = "Verdana"
        faceNode.fontColor = .blue
        faceNode.updateNewOptions(with: mouthOptions)
    }
    
    
   // @IBAction func handleChangeTextButton(_ sender: Any) {
//        changeTextToLarge()
//    }

    /////////////message input functions end//////////////
    //////////////////////////////////////////////////////
    
    
    @IBAction func HandleTextSizeButton(_ sender: UIButton) {
        
        
        if(textSizeButton.titleLabel!.text == "M" && messageField.text != ""){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "AvenirNextCondensed-Heavy"
            faceNode.fontColor = .red
            faceNode.updateNewOptions(with: mouthOptions)

            self.animSize = 3
            self.animMag = 1.5

        sender.setTitle("L", for: .normal)
        } else if (textSizeButton.titleLabel!.text == "L" && messageField.text != ""){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "AmericanTypewriter"
            faceNode.fontColor = .yellow
            faceNode.updateNewOptions(with: mouthOptions)
            self.animSize = 0.7
            self.animMag = 1

            sender.setTitle("S", for: .normal)
        }else if (textSizeButton.titleLabel!.text == "S" && messageField.text != ""){
            let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
            faceNode.fontFace = "Avenir-Medium"
            faceNode.fontColor = .white
            faceNode.updateNewOptions(with: mouthOptions)
            self.animSize = 1.3
            self.animMag = 1.5

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
        child?.scale = SCNVector3(self.animSize + jawOpenValue*6*animMag, self.animSize/8 + jawOpenValue*2*animMag, 0.1)
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

