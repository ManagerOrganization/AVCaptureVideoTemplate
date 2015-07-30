//
//  ViewController.swift
//  AVSessionTest
//
//  Created by qugang on 15/7/8.
//  Copyright (c) 2015年 qugang. All rights reserved.
//

import UIKit
import AVFoundation

class AVCaptireVideoPicController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var callBack :((face: UIImage) ->())?
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var pickUIImager : UIImageView = UIImageView(image: UIImage(named: "pick_bg"))
    var line : UIImageView = UIImageView(image: UIImage(named: "line"))
    var timer : NSTimer!
    var upOrdown = true
    var isStart = false
    
    
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
        timer =  NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "animationSate", userInfo: nil, repeats: true)
        // Do any additional setup after loading the view, typically from a nib.
        NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "isStartTrue", userInfo: nil, repeats: false)
    }
    
    func isStartTrue(){
        self.isStart = true
    }
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
        captureSession.stopRunning()
        
    }
    
    
    
    //动态显示扫描线的方法
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
    
    
    
    
    
    
    func beginSession() {
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
                let faceImage = UIImage(CGImage: context.createCGImage(ciImage, fromRect: face.bounds),scale: 1.0, orientation: .Right)
                
                NSLog("Face found at (%f,%f) of dimensions %fx%f", face.bounds.origin.x, face.bounds.origin.y,pickUIImager.frame.origin.x, pickUIImager.frame.origin.y)
                
                dispatch_async(dispatch_get_main_queue()) {
                    if (self.isStart)
                    {
                        self.dismissViewControllerAnimated(true, completion: nil)
                        self.didReceiveMemoryWarning()
                        
                        self.callBack!(face: faceImage!)
                    }
                    self.isStart = false
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
    
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
}
