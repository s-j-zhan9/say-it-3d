//
//  ViewController.swift
//  MobileLabCameraKit
//
//  Created by Nien Lam on 2/28/18.
//  Copyright © 2018 Mobile Lab. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Real time camera capture session.
    var captureSession = AVCaptureSession()

    // References to camera devices.
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?

    // Context for using Core Image filters.
    let context = CIContext()
    
    // Track orientation changes.
    var orientation: AVCaptureVideoOrientation?

    var value: Float = 0
    
    @IBAction func toggleCamera(_ sender: UIButton) {
        switchCameraInput()
    }
    
    @IBAction func slider(_ sender: UISlider) {
        value = sender.value
    }
    
    // Image view for filter image.
    @IBOutlet weak var filteredImage: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDevice(useBackCamera: true)
        setupInputOutput()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Detect orientation changes.
        orientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
    }
    

    // AVCaptureVideoDataOutputSampleBufferDelegate method
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        connection.videoOrientation = orientation!
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!).oriented(.upMirrored)

        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)

        
        //        1
        //        let comicEffect = CIFilter(name: "CIComicEffect")
        //        comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
        //        let cgImage = self.context.createCGImage(comicEffect!.outputImage!, from: cameraImage.extent)!
        
        
        //        2
        //        let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone", withInputParameters: ["inputWidth" : self.value, "inputSharpness": 1])
        //        CMYKHalftoneFilter!.setValue(cameraImage, forKey: kCIInputImageKey)
        //        let cgImage = self.context.createCGImage(CMYKHalftoneFilter!.outputImage!, from: cameraImage.extent)!
        
        //      3
        //        let EdgesEffectFilter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : self.value])
        //        EdgesEffectFilter!.setValue(cameraImage, forKey: kCIInputImageKey)
        //        let cgImage = self.context.createCGImage(EdgesEffectFilter!.outputImage!, from: cameraImage.extent)!
        
        
        
        // 4
        let cgImage = self.context.createCGImage(cameraImage, from: cameraImage.extent)!
        
        

        DispatchQueue.main.async {
            let filteredImage = UIImage(cgImage: cgImage)
            self.filteredImage.image = filteredImage
        }
    }
}




///////////////////////////////////////////////////////////////
// Helper methods to setup camera capture view.
extension ViewController {
   
    func setupDevice(useBackCamera: Bool) {
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
        
        currentCamera = useBackCamera ? backCamera : frontCamera
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

    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice?
    {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                         mediaType: AVMediaType.video, position: .unspecified) as AVCaptureDevice.DiscoverySession
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
            if oldCamera.device.position == .back {
                newCamera = frontCamera
            } else {
                newCamera = backCamera
            }
        }
        
        var newInput:AVCaptureDeviceInput!
        
        do {
            newInput = try AVCaptureDeviceInput(device: newCamera)
            self.captureSession.addInput(newInput)
        } catch {
            print(error)
        }
        
        self.captureSession.commitConfiguration()
    }
}





