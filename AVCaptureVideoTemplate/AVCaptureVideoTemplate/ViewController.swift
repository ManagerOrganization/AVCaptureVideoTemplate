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
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func takePictures(sender: UIButton) {
        let settingsStoryboard = UIStoryboard(name:"AVCaptireVideoPicStoryboard",bundle:nil)
        let viewController = settingsStoryboard.instantiateViewControllerWithIdentifier("AVCaptireVideoPic") as! AVCaptireVideoPicController
        
        viewController.callBack = { face  in
            self.imageView.image = face
        }
        self.presentViewController(viewController, animated: true, completion: nil)
        
    }
}

