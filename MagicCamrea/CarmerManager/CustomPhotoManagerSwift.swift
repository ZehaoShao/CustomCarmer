//
//  CustomPhotoManagerSwift.swift
//  MagicCamrea
//
//  Created by shaozehao on 15/12/7.
//  Copyright © 2015年 shaozehao. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import CoreMotion

//http://www.objccn.io/issue-21-3/

//闪光灯
enum KFlashLightState :Int {
    case KFlashLightOff = 0
    case KFlashLightOpen
    case KFlashLightAuto
    case KNoFlashLight

}

//聚焦
enum KFlashModeState:Int{
    case  KFlashFocusLock = 0
    case  KFlashFocusAuto
    case  KFlashFocusContinusAuto
}

enum carmerError : ErrorType {
    case  EvievoInput
}



class CustomPhotoManagerSwift: NSObject {
    var frontCamera      :AVCaptureDevice?
    var backCamera       :AVCaptureDevice?
    var Orientation      :AVCaptureVideoOrientation?
    var session          :AVCaptureSession?
    var videoInput       :AVCaptureDeviceInput?
    var stillImageOutput :AVCaptureStillImageOutput?
    var previewLayer     :AVCaptureVideoPreviewLayer?
    var image            :UIImage?
    var flashLightState  :KFlashLightState?
    
    func initializeCameraWithPreview(view:UIView) ->Void{
        if self.checkDeviceAuthorizationStatus() {
            self.initalSession(view)
        }
    }
   
    func checkDeviceAuthorizationStatus() ->Bool{
        if(AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Denied){
            let alterV :UIAlertView = UIAlertView.init(title: "提示", message: "当前相机不可用", delegate: nil, cancelButtonTitle:"确定", otherButtonTitles:"")
            alterV.show()
            return false
        }
        return true
     
    }
    
    
    func initalSession(preview:UIView) ->Void{
        self.session           = AVCaptureSession.init()
        //做异常处理
        do {
            try self.videoInput = AVCaptureDeviceInput.init(device: self.backCarmer())
        }catch{
            print("error")
        }
        self.stillImageOutput = AVCaptureStillImageOutput.init()
        self.previewLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
        
        // frame ..
        let kDeviceWidth  = UIScreen.mainScreen().bounds.size.width
        let kDeviceHeight  = UIScreen.mainScreen().bounds.size.height
        self.previewLayer!.frame = CGRect.init(x: 0, y:0, width:kDeviceWidth,height:(kDeviceHeight-160-20))
        self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.layer.addSublayer(self.previewLayer!)
        
        let outputSettings :NSDictionary = NSDictionary.init(object: AVVideoCodecJPEG, forKey: AVVideoCodecKey)
        self.stillImageOutput!.outputSettings = outputSettings as [NSObject : AnyObject]
        self.session!.sessionPreset = AVCaptureSessionPresetPhoto
        
        if self.session!.canAddInput(self.videoInput){
            self.session! .addInput(self.videoInput)
        }
        if self.session!.canAddOutput(self.stillImageOutput){
            self.session! .addOutput(self.stillImageOutput)
        }
        
        self.session! .startRunning()

    }
    
    func cameraWithPosition(position :AVCaptureDevicePosition) -> AVCaptureDevice{
        
        let devices :NSArray = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in devices {
            if(device.position == position)
            {
                return device as! AVCaptureDevice
            }
        }
        return AVCaptureDevice()
        
    }
    
    func fontCarmer() ->AVCaptureDevice {
        return self.cameraWithPosition(AVCaptureDevicePosition.Front)
    }
    
    func backCarmer()->AVCaptureDevice {
        return self.cameraWithPosition(AVCaptureDevicePosition.Back)
    }
    
//转换前后摄像头
    func switchCamera() ->Void{
        
        let carmerCount :NSInteger  = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count
        if carmerCount > 1 {
           var newVideoInput :AVCaptureDeviceInput = AVCaptureDeviceInput.init()
           let position     :AVCaptureDevicePosition = self.videoInput!.device.position
            if  position == AVCaptureDevicePosition.Back{
                do {
                    try newVideoInput = AVCaptureDeviceInput.init(device: self.fontCarmer())
                }catch{
                    print("error")
                }
                
            }else if position == AVCaptureDevicePosition.Front{
                do {
                    try newVideoInput = AVCaptureDeviceInput.init(device: self.backCarmer())
                }catch{
                    print("error")
                }
                
            }else{
                return;
            }
                self.session!.beginConfiguration()
                self.session!.removeInput(self.videoInput)
                if(self.session!.canAddInput(newVideoInput)){
                    self.session! .addInput(newVideoInput)
                    self.videoInput = newVideoInput
                }else{
                    self.session!.addInput(self.videoInput)
                }
                self.session! .commitConfiguration()
            }
        }

//拍照
     func takePhoto() ->Void {
        
        print("\(self.stillImageOutput!)")
        print("\(self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo))")
        let videoConnection :AVCaptureConnection = self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
        if  videoConnection is AVCaptureConnection {
//            if videoConnection.supportsVideoOrientation{
//                if self.Orientation! is AVCaptureVideoOrientation {
//                    videoConnection.videoOrientation = self.Orientation!
//                }
//            }
            
            self.stillImageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection) { (imageDataSampleBuffer:CMSampleBufferRef!, error:NSError!) -> Void in
                if imageDataSampleBuffer == nil {
                    return;
                }
                let data:NSData   = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                let image:UIImage = UIImage.init(data: data)!
                self.image = image
                
            }
        }else{
            print("take photo  error")
        }

     }
    
//设置闪光灯
    func FlashLightState(state:KFlashLightState) ->Void{
        let current_camera:AVCaptureDevice = self.cameraWithPosition(self.videoInput!.device.position)
        if  state != KFlashLightState.KNoFlashLight {
            switch state {
            case .KFlashLightOpen:
                do {
                    try  current_camera.lockForConfiguration()
                    if current_camera.isFlashModeSupported(AVCaptureFlashMode.On){
                        current_camera.flashMode = AVCaptureFlashMode.On
                    }
                    current_camera.unlockForConfiguration()
   
                }catch{
                    print("error")
                }
                break
            case .KFlashLightAuto:
                do {
                    try  current_camera.lockForConfiguration()
                    if current_camera.isFlashModeSupported(AVCaptureFlashMode.Auto){
                        current_camera.flashMode = AVCaptureFlashMode.Auto
                    }
                    current_camera.unlockForConfiguration()
                    
                }catch{
                    print("error")
                }
                break
            case .KFlashLightOff :
                do {
                    try  current_camera.lockForConfiguration()
                    if current_camera.isFlashModeSupported(AVCaptureFlashMode.Off){
                        current_camera.flashMode = AVCaptureFlashMode.Off
                    }
                    current_camera.unlockForConfiguration()
                    
                }catch{
                    print("error")
                }
                break
            default: break
            }
        }
    
    }
    
    func FlashModeState(state:KFlashModeState) ->Void{
        let current_camera:AVCaptureDevice = self.cameraWithPosition(self.videoInput!.device.position)
            switch state {
            case .KFlashFocusLock:
                do {
                    try  current_camera.lockForConfiguration()
                    if current_camera.isFocusModeSupported(AVCaptureFocusMode.Locked){
                        current_camera.focusMode = AVCaptureFocusMode.Locked
                    }
                    current_camera.unlockForConfiguration()
                    
                }catch{
                    print("error")
                }
                break
            case .KFlashFocusAuto:
                do {
                    try  current_camera.lockForConfiguration()
                    if current_camera.isFocusModeSupported(AVCaptureFocusMode.AutoFocus){
                        current_camera.focusMode = AVCaptureFocusMode.AutoFocus
                    }
                    current_camera.unlockForConfiguration()
                    
                }catch{
                    print("error")
                }
                break
            default :
                do {
                    try  current_camera.lockForConfiguration()
                    if current_camera.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus){
                        current_camera.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
                    }
                    current_camera.unlockForConfiguration()
                    
                }catch{
                    print("error")
                }
               break
            }
    }
    
    func StopTakePhoto() ->Void{
        self.session! .stopRunning()
    }
    func startTakePhoto() ->Void{
        self.session!.startRunning()
    }
    
    
}
