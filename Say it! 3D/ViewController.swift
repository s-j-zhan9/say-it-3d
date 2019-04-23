import UIKit
import ARKit
import ReplayKit
import RecordButton

class ViewController: UIViewController{
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var textInputView: UIView!
    
    @IBOutlet weak var messageField: UITextField!
    var mouthOptions = ["Enter your Message"]

    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    
    //Record Button
    var recordButton : RecordButton!
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //
    //
    //create record button
    let recordButton = RecordButton(frame: CGRect(x: 0,y: 0,width: 70,height: 70))
    view.addSubview(recordButton)
    recordButton.center = self.view.center
    recordButton.progressColor = .red
    recordButton.closeWhenFinished = false
    
    //The recordButton needs a target for start and stopping the progress timer. Add this code after initialization of the recordButton (usualy in viewDidLoad())
    recordButton.addTarget(self, action: #selector(ViewController.record), for: .touchDown)
    recordButton.addTarget(self, action: #selector(ViewController.stop), for: UIControl.Event.touchUpInside)
    recordButton.center.x = self.view.center.x

    textInputView.isHidden = true
    
    guard ARFaceTrackingConfiguration.isSupported else { fatalError() }
    sceneView.delegate = self

    
  }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //record functions
    @objc func record() {
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.updateProgress), userInfo: nil, repeats: true)
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
        self.progressTimer.invalidate()
    }
    
    //text input
    
    @IBAction func textInputButton(_ sender: Any) {
        textInputView.isHidden = false
        messageField.becomeFirstResponder()


    }
    //submit recorded speach to array and refresh the array displayed on top
    @IBAction func submitButton(_ sender: Any) {
        
        //add text field input to array
        //mouthOptions.insert(messageField.text as! String, at: 0)
        mouthOptions = [messageField.text as! String]
        
        // Update new Node Options
        let emojiNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! EmojiNode
        emojiNode.updateNewOptions(with: mouthOptions)
        //
        //show updated array
        //messageResult.text = mouthOptions.joined(separator:" - ")
        messageField.text = ""
        messageField.resignFirstResponder()
        textInputView.isHidden = true
        
    }
    //touch outside the message field to dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        messageField.resignFirstResponder()

    }
    
    //initiate AR tracking
    override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let configuration = ARFaceTrackingConfiguration()
    
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    sceneView.session.pause()
  }
  //use EmojiNode.swift to map facial features, and animate on jaw open
  func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
    for (feature, indices) in zip(features, featureIndices) {
      let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
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
      let node = result.node as? EmojiNode {
      node.next()
    }
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
    
    
    let mouthNode = EmojiNode(with: mouthOptions)
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



