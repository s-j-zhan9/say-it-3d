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
    
    var nodesCreated = false
    
    var presetNum = 1
    
    @IBOutlet weak var fontButton: UIButton!
    @IBOutlet weak var countDownLabel: UILabel!
    
    let textAllowed = 20
    var textTimer = Timer()
    var currentFontFace = "Avenir-Black"
    var currentFontSize = "M"
    
    let white = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
    let red = UIColor(red: 255/255, green: 20/255, blue: 0/255, alpha: 1.0)
    let yellow = UIColor(red: 236/255, green: 166/255, blue: 18/255, alpha: 1.0)
    let pink = UIColor(red: 255/255, green: 173/255, blue: 150/255, alpha: 1.0)
    let green = UIColor(red: 72/255, green: 243/255, blue: 166/255, alpha: 1.0)
    let aqua = UIColor(red: 101/255, green: 254/255, blue: 255/255, alpha: 1.0)
    let blue = UIColor(red: 50/255, green: 143/255, blue: 255/255, alpha: 1.0)
    let purple = UIColor(red: 226/255, green: 85/255, blue: 255/255, alpha: 1.0)
    let black = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)

    var currentFontColor: UIColor!

    @IBOutlet weak var tutorialView: UIView!
    
    //color buttons
    @IBOutlet weak var whiteColorButton: UIButton!
    @IBOutlet weak var redColorButton: UIButton!
    @IBOutlet weak var yellowColorButton: UIButton!
    @IBOutlet weak var pinkColorButton: UIButton!
    @IBOutlet weak var greenColorButton: UIButton!
    @IBOutlet weak var aquaColorButton: UIButton!
    @IBOutlet weak var blueColorButton: UIButton!
    @IBOutlet weak var purpleColorButton: UIButton!
    @IBOutlet weak var blackColorButton: UIButton!
    
    @IBOutlet weak var textInputButton: UIButton!
    
    
    @IBOutlet weak var tutorialButton: UIButton!
    
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
    var animSize: Float = 1.6
    
    //magnitude of animation
    var animMag: Float = 1.8
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    currentFontColor = white
    
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
    
    //record button styling
    recordButton.layer.shadowColor = UIColor.black.cgColor
    recordButton.layer.shadowRadius = 3.0
    recordButton.layer.shadowOpacity = 0.3
    recordButton.layer.shadowOffset = CGSize(width: 0, height: 1)
    recordButton.layer.masksToBounds = false
    
    //textInputButton styling
    textInputButton.layer.shadowColor = UIColor.black.cgColor
    textInputButton.layer.shadowRadius = 3.0
    textInputButton.layer.shadowOpacity = 0.3
    textInputButton.layer.shadowOffset = CGSize(width: 0, height: 1)
    textInputButton.layer.masksToBounds = false
    
    //textSizeButton styling
    textSizeButton.layer.shadowColor = UIColor.black.cgColor
    textSizeButton.layer.shadowRadius = 3.0
    textSizeButton.layer.shadowOpacity = 0.3
    textSizeButton.layer.shadowOffset = CGSize(width: 0, height: 1)
    textSizeButton.layer.masksToBounds = false
    
    //set up Scene Kit View Recorder to record ARSceneView
    recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView)
    

    //hide textInputView on launch
    textInputView.isHidden = true
    tutorialView.isHidden = true

    
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
            stop()
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
        tutorialButton.isHidden = true
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
            updateNode()
        }
        messageField.resignFirstResponder()
        textInputView.isHidden = true
        tutorialButton.isHidden = false
    }
    
    //OK button to submit string
    @IBAction func handleSubmitButton(_ sender: Any) {
        submitText()
    }
    //tap gesture to submit string
    @IBAction func handleTapToSubmit(_ sender: Any) {
        submitText()
    }
    
    func setFont(newFont: String!,newTitle: String!){
        currentFontFace = newFont
        messageField.font = UIFont(name: currentFontFace, size: 36)
        fontButton.setTitle(newTitle, for: .normal)
        //fontButton.titleLabel?.font =  UIFont(name: currentFontFace, size: 13)
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.fontFace = currentFontFace
    }
    
    
    @IBAction func handleFontButton(_ sender: UIButton) {
        if(currentFontFace == "Avenir-Black"){
            setFont(newFont: "AvenirNext-HeavyItalic",newTitle: "BOLD")

        } else if (currentFontFace == "AvenirNext-HeavyItalic"){
            setFont(newFont: "Baskerville-SemiBold",newTitle: "ELEGANT")

        }else if (currentFontFace == "Baskerville-SemiBold"){
            setFont(newFont: "Courier",newTitle: "TYPEWRITTER")

        }else if (currentFontFace == "Courier"){
            setFont(newFont: "Avenir-Black",newTitle: "REGULAR")
        }
    }

    @IBAction func handleWhiteButton(_ sender: Any) {
        setColor(newColor: white)
    }
        @IBAction func handleRedButton(_ sender: Any) {
        setColor(newColor: red)
    }
        @IBAction func handleYellowButton(_ sender: Any) {
        setColor(newColor: yellow)
    }
        @IBAction func handlePinkButton(_ sender: Any) {
        setColor(newColor: pink)
    }
    @IBAction func handleGreenButton(_ sender: Any) {
        setColor(newColor: green)
    }
    @IBAction func handleAquaButton(_ sender: Any) {
        setColor(newColor: aqua)
    }
    @IBAction func handleBlueButton(_ sender: Any) {
        setColor(newColor: blue)
    }
    @IBAction func handlePurpleButton(_ sender: Any) {
        setColor(newColor: purple)
    }
    @IBAction func handleBlackButton(_ sender: Any) {
        setColor(newColor: black)
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
            setFont(newFont: "Avenir-Black",newTitle: "REGULAR")
            setColor(newColor: white)
            setSize(newFontSize: "M")
            updateNode()
        } else if (presetNum == 2){
            setColor(newColor: red)
            setFont(newFont: "AvenirNext-HeavyItalic",newTitle: "BOLD")
            setSize(newFontSize: "L")
            updateNode()
        } else if (presetNum == 3){
            setFont(newFont: "Baskerville-SemiBold",newTitle: "ELEGANT")
            setColor(newColor: yellow)
            setSize(newFontSize: "M")
            updateNode()
        } else if (presetNum == 4){
            setFont(newFont: "Courier",newTitle: "TYPEWRITTER")
            setColor(newColor: pink)
            setSize(newFontSize: "S")
            updateNode()
        }
    }
    
    func updateNode(){
        if (nodesCreated == true){
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.updateNewOptions(with: mouthOptions)
        }
    }
    
    func setColor(newColor: UIColor!){
        currentFontColor = newColor
        messageField.textColor = currentFontColor
        let faceNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! FaceNode
        faceNode.fontColor = currentFontColor
        
        redColorButton.isSelected = false
        yellowColorButton.isSelected = false
        pinkColorButton.isSelected = false
        greenColorButton.isSelected = false
        aquaColorButton.isSelected = false
        blueColorButton.isSelected = false
        purpleColorButton.isSelected = false
        blackColorButton.isSelected = false
        
        if (currentFontColor == red){
            redColorButton.isSelected = true
        }
        if (currentFontColor == yellow){
            yellowColorButton.isSelected = true
        }
        if (currentFontColor == pink){
            pinkColorButton.isSelected = true
        }
        if (currentFontColor == green){
            greenColorButton.isSelected = true
        }
        if (currentFontColor == aqua){
            aquaColorButton.isSelected = true
        }
        if (currentFontColor == blue){
            blueColorButton.isSelected = true
        }
        if (currentFontColor == purple){
            purpleColorButton.isSelected = true
        }
        if (currentFontColor == white){
            whiteColorButton.isSelected = true
        }
    }
    
    @IBAction func HandleTextSizeButton(_ sender: UIButton) {
        if(currentFontSize == "M"){
            setSize(newFontSize: "L")
        } else if (currentFontSize == "L"){
            setSize(newFontSize: "S")
        }else if (currentFontSize == "S"){
            setSize(newFontSize: "M")
        }
    }
    
    func setSize(newFontSize: String!){
        currentFontSize = newFontSize
        if (newFontSize == "M"){
            self.animSize = 1.6
            self.animMag = 1.8
        } else if (newFontSize == "L"){
            self.animSize = 4
            self.animMag = 1.9
        }else if (newFontSize == "S"){
            self.animSize = 0.7
            self.animMag = 0.7
        }
        textSizeButton.setTitle(currentFontSize, for: .normal)
    }
    
    
    //tutorial
    
    @IBAction func handleTutorialButton(_ sender: Any) {
        tutorialView.isHidden = false
    }
    
    @IBAction func tapToDismissTutorialView(_ sender: Any) {
        tutorialView.isHidden = true

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
        child?.scale = SCNVector3(self.animSize + jawOpenValue*10*animMag, self.animSize/8 + jawOpenValue*animMag, 0.1)
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
    nodesCreated = true
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

