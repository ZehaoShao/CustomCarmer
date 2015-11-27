//
//  CustomPhotoManager.m
//  BacKGroundView
//
//  Created by shaozehao on 15/8/17.
//  Copyright (c) 2015年 shaozehao. All rights reserved.
//

#import "CustomPhotoManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#define kDeviceWidth                [UIScreen mainScreen].bounds.size.width
#define kDeviceHeight               [UIScreen mainScreen].bounds.size.height

@interface CustomPhotoManager ()
{
    AVCaptureDevice *_frontCamera;//前置摄像头
    AVCaptureDevice *_backCamera;//后置摄像头
}
@property (nonatomic,strong)        AVCaptureSession * session;
//AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic, strong)       AVCaptureDeviceInput        * videoInput;
//AVCaptureDeviceInput对象是输入流
@property (nonatomic, strong)       AVCaptureStillImageOutput   * stillImageOutput;
//照片输出流对象，当然我的照相机只有拍照功能，所以只需要这个对象就够了
@property (nonatomic, strong)       AVCaptureVideoPreviewLayer  * previewLayer;
@property (nonatomic, strong)       UIImage  * image;
@property (nonatomic, strong)       NSMutableArray  * mImagesArrary;
@property (nonatomic, assign)       BOOL   isRight;
@end

@implementation CustomPhotoManager



-(void)initializeCameraWithPreview:(UIView *)preview
{
      //检测是否授权
    if ([self checkDeviceAuthorizationStatus]) {
        [self initalSession:preview];
    }
}
- (BOOL)checkDeviceAuthorizationStatus //>=iOS_7.0
{
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]==AVAuthorizationStatusDenied) {
        NSLog(@"相机不可用~ ~ ~");
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"当前相机不可用" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return  NO;
    }else{
        return YES;
    }
}
-(void)initalSession:(UIView *)preview{
    //这个方法的执行我放在init方法里了
    self.session = [[AVCaptureSession alloc] init];
   self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:nil];

    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
#warning preview.frame
     self.previewLayer.frame = CGRectMake(0,0,kDeviceWidth,kDeviceHeight-20-162);
   [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [preview.layer addSublayer:self.previewLayer];
    
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    
    [self.stillImageOutput setOutputSettings:outputSettings];
    [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    if (self.session) {
        [self.session startRunning];
    }
}
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}
//转换前后摄像头
- (void)switchCamera {
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[_videoInput device] position];
        
        if (position == AVCaptureDevicePositionBack)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        else if (position == AVCaptureDevicePositionFront)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        else
            return;
        
        if (newVideoInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                [self setVideoInput:newVideoInput];
            } else {
                [self.session addInput:self.videoInput];
            }
            [self.session commitConfiguration];
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
    }
}
//拍照
-(void)takePhoto{
    AVCaptureConnection * videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage * image = [UIImage imageWithData:imageData];
        NSLog(@"方向===========================================%ld",(long)image.imageOrientation);
        self.image = image;
        
         NSLog(@"image size = =-=--------     %@",NSStringFromCGSize(image.size));
        
        
        
        
        UIImage *image1 = [self scaleAndRotateImage:image];
        NSData *data = UIImageJPEGRepresentation(image1,1);
        NSLog(@"image size = %@",NSStringFromCGSize(image1.size));
        //CIPhotoEffectFade
        //CIPhotoEffectChrome
        //CIFalseColor
        //
        //做滤镜处理 可去掉
       // [self effectImage:image byFilterName:@"CIPhotoEffectChrome"];
        if (self.mImagesArrary == nil) {
            self.mImagesArrary = [NSMutableArray array];
        }
//        NSString *fileName = [NSString stringWithFormat:@"%ld",(long) ([[NSDate date] timeIntervalSince1970])];
//        BOOL isFileExist = NO;
//        for (PhotoModel *pModel in self.mImagesArrary) {
//            if ([pModel.localPath isEqualToString:fileName]) {
//                isFileExist = YES;
//            }
//        }
//        if (!isFileExist) {
//            BOOL isOK = [KUploadImageManager writeImageDatasToLocalPath:fileName andImageData:data];
//            if (isOK) {
//                PhotoModel *model = [PhotoModel item];
//                model.localPath = fileName;
//                [self.mImagesArrary addObject:model];
//            }
//            NSNotificationCenterPostName(@"ChangePhotosCount");
//        }
    }];

}

//检查闪光灯
-(void)CheckflashLightWithCamera:(AVCaptureDevice *)camera
{
    if ([camera hasFlash]){
        [camera lockForConfiguration:nil];//加锁
        self.flashLightState=KFlashLightOff;
        [self setFlashLightState:KFlashLightOff];
        [camera unlockForConfiguration];
    }else{
        self.flashLightState=KNoFlashLight;
    }
}

-(NSMutableArray*)getImagesArrary{
    if (self.mImagesArrary == nil) {
        self.mImagesArrary = [NSMutableArray array];
    }
    return _mImagesArrary;
}
//设置闪光灯
-(void)setFlashLightState:(enum KFlashLightState)FlashLightState
{
    AVCaptureDevice *current_camera=[self cameraWithPosition:[[_videoInput device] position]];
    _flashLightState = FlashLightState;
    //设置闪光灯
    if (FlashLightState!=KNoFlashLight) {
        switch (FlashLightState) {
            case KFlashLightOpen:
                [current_camera lockForConfiguration:nil];
                [current_camera setFlashMode:AVCaptureFlashModeOn]; //闪光灯打开
                [current_camera unlockForConfiguration];
                break;
            case KFlashLightOff:
                [current_camera lockForConfiguration:nil];
                [current_camera setFlashMode:AVCaptureFlashModeOff];//闪光灯关闭
                [current_camera unlockForConfiguration];
                break;
            case KFlashLightAuto:
                [current_camera lockForConfiguration:nil];
                [current_camera setFlashMode:AVCaptureFlashModeAuto];//闪光灯自动
                [current_camera unlockForConfiguration];
                break;
            default:
                break;
        }
    }
}
//停止
- (void)StopTakePhoto{
    if (_session) {
        [_session stopRunning];
    }
}
//开始
- (void)startTakePhoto{
    if (_session) {
        [_session startRunning];
    }
}
#pragma mark--保存到相册
-(void)SavePictureToLibraryWithImage:(UIImage *)image
{
    ALAssetsLibrary*library=[[ALAssetsLibrary alloc]init];
    [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
        
    }];
}

// 滤镜
/**
 似乎只有一部分可以在 iOS 中使用
 @"None",
 @"CIFalseColor",
 @"CIPhotoEffectChrome",
 @"CIPhotoEffectFade",
 
 //                    @"CIColorCrossPolynomial",
 //                    @"CIColorCube",
 //                    @"CIColorCubeWithColorSpace",
 //                    @"CIColorInvert",
 //                    @"CIColorMap",
 //                    @"CIColorMonochrome",
 //                    @"CIColorPosterize",
 //                    @"CIMaskToAlpha",
 //                    @"CIMaximumComponent",
 //                    @"CIMinimumComponent",
 //                    @"CIPhotoEffectInstant",
 //                    @"CIPhotoEffectMono",
 //                    @"CIPhotoEffectNoir",
 //                    @"CIPhotoEffectProcess",
 //                    @"CIPhotoEffectTonal",
 //                    @"CIPhotoEffectTransfer",
 //                    @"CISepiaTone",
 //                    @"CIVignette",
 //                    @"CIVignetteEffect",

 */
- (UIImage *) effectImage: (UIImage *)uIImage byFilterName:(NSString *)filterName;
{
    if ([filterName isEqualToString:@"None"]) {
        return uIImage;
    }
    
    UIImage *tempImage = [self scaleAndRotateImage:uIImage];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:tempImage]; // 解决滤镜后图片方向不对的问题
    
    CIFilter *filter = [CIFilter filterWithName:filterName];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGRect extent = [result extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return filteredImage;
}


- (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 1280; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
     NSLog(@"方向new  ===========================================%ld",(long)image.imageOrientation);
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 0
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 1
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 5
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 2
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 3
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
   CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

@end
