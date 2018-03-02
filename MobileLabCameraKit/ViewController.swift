//
//  ViewController.swift
//  MobileLabCameraKit
//
//  Created by Nien Lam on 2/28/18.
//  Copyright © 2018 Mobile Lab. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation


// Sample filters and settings.
// For more resournces/examples:
//   https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
//   https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html
//   https://github.com/FlexMonkey/Filterpedia

//let NoFilter = "No Filter"
//let NoFilterFilter: CIFilter? = nil

let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone", withInputParameters: ["inputWidth" : 20, "inputSharpness": 1])

let ComicEffectFilter = CIFilter(name: "CIComicEffect")

let CrystallizeFilter = CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius" : 30])

let EdgesEffectFilter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : 10])

let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate", withInputParameters: ["inputScale" : 40])

let InvertFilter = CIFilter(name: "CIColorInvert")

let PointillizeFilter = CIFilter(name: "CIPointillize", withInputParameters: ["inputRadius" : 30])

let LineOverlayFilter = CIFilter(name: "CILineOverlay")

let PosterizeFilter = CIFilter(name: "CIColorPosterize", withInputParameters: ["inputLevels" : 5])

let Filters = [
    nil,
    CMYKHalftoneFilter,
    ComicEffectFilter,
    CrystallizeFilter,
    EdgesEffectFilter,
    HexagonalPixellateFilter,
    InvertFilter,
    PointillizeFilter,
    LineOverlayFilter,
    PosterizeFilter
]


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate {
    
    // Real time camera capture session.
    var captureSession = AVCaptureSession()

    // References to camera devices.
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?

    // Context for using Core Image filters.
    let context = CIContext()
    
    // Track device orientation changes.
    var orientation: AVCaptureVideoOrientation = .portrait

    // Use location manager to get heading.
    let locationManager = CLLocationManager()

    // Reference to current filter.
    var currentFilter: CIFilter?
    var filterIndex = 0
    
    // Image view for filtered image.
    @IBOutlet weak var filteredImage: UIImageView!

    // Label for heading.
    @IBOutlet weak var headingLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDevice()
        setupInputOutput()

        // Configure location manager to get heading.
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Detect device orientation changes.
        orientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
    }
    

    // CLLocationManagerDelegate method returns heading.
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        headingLabel.text = "Heading: \(Int(heading.magneticHeading))"
    }


    // Cycle through filters.
    @IBAction func toggleFilterButton(_ sender: UIButton) {
        filterIndex = filterIndex + 1 == Filters.count ? 0 : filterIndex + 1

        currentFilter =  Filters[filterIndex]
    }
    
    // Toggle front/back camera
    @IBAction func toggleCameraButton(_ sender: UIButton) {
        switchCameraInput()
    }

    
    // AVCaptureVideoDataOutputSampleBufferDelegate method.
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        // Set correct device orientation.
        connection.videoOrientation = orientation
        
        // Get pixel buffer.
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var cameraImage = CIImage(cvImageBuffer: pixelBuffer!)

        // Mirror camera image if using front camera.
        if currentCamera == frontCamera {
            cameraImage = cameraImage.oriented(.upMirrored)
        }

        // Get the filtered image if a currentFilter is set.
        var filteredImage: UIImage!
        if currentFilter == nil {
            filteredImage =  UIImage(ciImage: cameraImage)
        } else {
            self.currentFilter!.setValue(cameraImage, forKey: kCIInputImageKey)
            let cgImage = self.context.createCGImage(self.currentFilter!.outputImage!, from: cameraImage.extent)!
            filteredImage = UIImage(cgImage: cgImage)
        }
        
        // Set image view outlet with filtered image.
        DispatchQueue.main.async {
            self.filteredImage.image = filteredImage
        }
    }
}



///////////////////////////////////////////////////////////////
// Helper methods to setup camera capture view.
extension ViewController {
   
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    func setupInputOutput() {
        do {
            setupCorrectFramerate(currentCamera: currentCamera!)
            
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {
            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }

    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                         mediaType: AVMediaType.video,
                                                         position: .unspecified) as AVCaptureDevice.DiscoverySession
        for device in discovery.devices as [AVCaptureDevice] {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    func switchCameraInput() {
        self.captureSession.beginConfiguration()
        
        var existingConnection:AVCaptureDeviceInput!
        
        for connection in self.captureSession.inputs {
            let input = connection as! AVCaptureDeviceInput
            if input.device.hasMediaType(AVMediaType.video) {
                existingConnection = input
            }
            
        }
        
        self.captureSession.removeInput(existingConnection)
        
        var newCamera:AVCaptureDevice!
        if let oldCamera = existingConnection {
            newCamera = oldCamera.device.position == .back ? frontCamera : backCamera
            currentCamera = newCamera
        }
        
        var newInput: AVCaptureDeviceInput!
        
        do {
            newInput = try AVCaptureDeviceInput(device: newCamera)
            self.captureSession.addInput(newInput)
        } catch {
            print(error)
        }
        
        self.captureSession.commitConfiguration()
    }
}
