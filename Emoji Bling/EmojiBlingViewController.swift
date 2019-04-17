/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import ARKit
import Speech

class EmojiBlingViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate {
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var messageResult: UITextView!
    var mouthOptions = ["Nooo","BREAK","OMG"]

    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    
    //////////////////////////////////////////////
    ////////////vars for audio input//////////////
    //////////////////////////////////////////////
    @IBOutlet weak var detectedTextLabel: UILabel!
    
    var timer: Timer?
    var change: CGFloat = 0.01
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var recorder: AVAudioRecorder!
    
    var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
    
    //last best word from voice recognition
    var lastBestString = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //messageField Styling
    messageField.layer.borderWidth = 2
    messageField.layer.cornerRadius = 5
    messageField.layer.borderColor = UIColor.white.cgColor
    messageField.delegate = self
    
    guard ARFaceTrackingConfiguration.isSupported else { fatalError() }
    sceneView.delegate = self
    
    messageResult.text = mouthOptions.joined(separator:" - ")

    
    // Call this when updateing options.
    let emojiNode = sceneView.scene.rootNode.childNode(withName: "mouth", recursively: true) as! EmojiNode
    emojiNode.updateNewOptions(with: ["hi", "bye"])
    //
    
  }
    
    //submit recorded speach to array and refresh the array displayed on top
    @IBAction func submitButton(_ sender: Any) {
        mouthOptions.insert(messageField.text as! String, at: 0)
        messageResult.text = mouthOptions.joined(separator:" - ")
        messageField.text = ""
        print(mouthOptions)
        
    }
    //touch outside the message field to dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        messageField.resignFirstResponder()
        messageResult.resignFirstResponder()

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
        child?.scale = SCNVector3(1 + jawOpenValue*6, 0.1 + jawOpenValue*2, 0.2)
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
    
    //speech recognition
    @IBAction func startRecording(_ sender: Any) {
        self.requestSpeechAuthorization()
        
      
        
        if self.recorder != nil {
            return
        }
        
        let url: NSURL = NSURL(fileURLWithPath: "/dev/null")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.recorder = try AVAudioRecorder(url: url as URL, settings: settings )
            self.recorder.delegate = self
            self.recorder.isMeteringEnabled = true
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.record)))
            
            self.recorder.record()
        
        } catch {
            print("Fail to record.")
        }
    }
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("authorized")
                    self.recordAndRecognizeSpeech()
                case .denied:
                    print("denied")
                case .restricted:
                    print("restricted")
                case .notDetermined:
                    print("notDetermined")
                @unknown default:
                    return
                }
            }
        }
    }
    
    @IBAction func submitSpeech(_ sender: Any) {
        mouthOptions.insert(detectedTextLabel.text as! String, at: 0)
        detectedTextLabel.text = ""

    }

    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                var bestString = result.bestTranscription.formattedString
                self.detectedTextLabel.text = bestString
                
                if let lastSegment = result.bestTranscription.segments.last,
                    lastSegment.duration > self.mostRecentlyProcessedSegmentDuration {
                    self.mostRecentlyProcessedSegmentDuration = lastSegment.duration
                    
                    /////////////////////////////////////////////////////////////////////
                    // Get last spoken word.
                    // Process request here.
                    
                    let string = lastSegment.substring
                    
                    if string.lowercased() == "green" {
                        self.view.backgroundColor = .green
                    } else if string.lowercased() == "red" {
                        self.view.backgroundColor = .red
                    } else if string.lowercased() == "black" {
                        self.view.backgroundColor = .black
                    } else if string.lowercased() == "clear" {
                        bestString = ""
                        print("bestString is\(bestString)")
                        self.detectedTextLabel.text = bestString
                        
                    }
                    
                    /////////////////////////////////////////////////////////////////////
                }
                
            } else if let error = error {
                self.sendAlert(message: "There has been a speech recognition error.")
                print(error)
            }
            
        })
    }
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}


extension EmojiBlingViewController: ARSCNViewDelegate {
  
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

extension EmojiBlingViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}



