//
//  CustomPhotoManager.h
//  BacKGroundView
//
//  Created by shaozehao on 15/8/17.
//  Copyright (c) 2015年 shaozehao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//闪光灯
enum KFlashLightState{
    KFlashLightOff=0,//关闭
    KFlashLightOpen,//开启
    KFlashLightAuto,//自动
    KNoFlashLight//不可用
};



@interface CustomPhotoManager : NSObject
@property (nonatomic,assign) enum KFlashLightState flashLightState;

//+ (CustomPhotoManager *)sharedInstance;
-(void)initializeCameraWithPreview:(UIView *)preview;
//初始化AVCaptureSession
-(void)setFlashLightState:(enum KFlashLightState)FlashLightState;
//转换前后摄像头
-(void)switchCamera;
//拍照
-(void)takePhoto;

//连拍保存图像数组
-(NSMutableArray*)getImagesArrary;

- (void)startTakePhoto;
- (void)StopTakePhoto;


//保存到相册需要时在用
-(void)SavePictureToLibraryWithImage:(UIImage *)image;
// Code from: http://discussions.apple.com/thread.jspa?messageID=7949889
// 添加滤镜需要时再用
- (UIImage *) effectImage: (UIImage *)uIImage byFilterName:(NSString *)filterName;
- (UIImage *)scaleAndRotateImage:(UIImage *)image;


@end
