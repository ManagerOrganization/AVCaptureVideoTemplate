//
//  ViewController.swift
//  AVSessionTest
//
//  Created by qugang on 15/7/8.
//  Copyright (c) 2015年 qugang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var pickUIImager : UIImageView = UIImageView(image: UIImage(named: "pick_bg"))
    var line : UIImageView = UIImageView(image: UIImage(named: "line"))
    var timer : NSTimer!
    var upOrdown = true
    var isStart = true
    var displayImage = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if (device.position == AVCaptureDevicePosition.Front) {
                    captureDevice = device as?AVCaptureDevice
                    if captureDevice != nil {
                        println("Capture Device found")
                        beginSession()
                    }
                }
            }
        }
        pickUIImager.frame = CGRect(x: self.view.bounds.width / 2 - 100, y: self.view.bounds.height / 2 - 100,width: 200,height: 200)
        line.frame = CGRect(x: self.view.bounds.width / 2 - 100, y: self.view.bounds.height / 2 - 100, width: 200, height: 2)
        self.view.addSubview(pickUIImager)
        self.view.addSubview(line)
        self.view.addSubview(displayImage)
        timer =  NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "animationSate", userInfo: nil, repeats: true)
        // Do any additional setup after loading the view, typically from a nib.
      //  NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "isStartTrue", userInfo: nil, repeats: false)
    }
    
    func isStartTrue(){
        self.isStart = true
    }
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
        captureSession.stopRunning()
        
    }
    
    func animationSate(){
        if upOrdown {
            if (line.frame.origin.y >= pickUIImager.frame.origin.y + 200)
            {
                upOrdown = false
            }
            else
            {
                line.frame.origin.y += 2
            }
        } else {
            if (line.frame.origin.y <= pickUIImager.frame.origin.y)
            {
                upOrdown = true
            }
            else
            {
                line.frame.origin.y -= 2
            }
        }
    }
    
    func configureDevice() {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = .Locked
            device.unlockForConfiguration()
        }
    }
    func beginSession() {
        
        // configureDevice()
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        let output = AVCaptureVideoDataOutput()
        
        let cameraQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]
        captureSession.addOutput(output)
        
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = "AVLayerVideoGravityResizeAspect"
        previewLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        if(self.isStart)
        {
            let resultImage = sampleBufferToImage(sampleBuffer)
            
            let context = CIContext(options:[kCIContextUseSoftwareRenderer:true])
            let detecotr = CIDetector(ofType:CIDetectorTypeFace,  context:context, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh])
            
            
            
            
            let ciImage = CIImage(image: resultImage)
            
            let results:NSArray = detecotr.featuresInImage(ciImage,options: ["CIDetectorImageOrientation" : 6])
            
            for r in results {
                let face:CIFaceFeature = r as! CIFaceFeature;
                let faceImage = UIImage(CGImage: context.createCGImage(ciImage, fromRect: face.bounds))
                
                NSLog("Face found at (%f,%f) of dimensions %fx%f", face.bounds.origin.x, face.bounds.origin.y,pickUIImager.frame.origin.x, pickUIImager.frame.origin.y)
                
                dispatch_async(dispatch_get_main_queue()) {
                    {
                        self.displayImage.image = faceImage
                    }
                }
            }
        }
    }
    private func sampleBufferToImage(sampleBuffer: CMSampleBuffer!) -> UIImage {
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent = 8
        var bitmapInfo = CGBitmapInfo((CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue) as UInt32)
        
        
        let newContext = CGBitmapContextCreate(baseAddress, width, height, bitsPerCompornent, bytesPerRow, colorSpace, bitmapInfo) as CGContextRef
        
        let imageRef: CGImageRef = CGBitmapContextCreateImage(newContext)
        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)!
        
        return resultImage
    }
}

