//
//  PhotoCollectionVC.m
//  EditingAssistant
//
//  Created by shaozehao on 15/8/21.
//  Copyright (c) 2015年 sohu. All rights reserved.
//

#import "PhotoCollectionVC.h"
#import "CustomPhotoManager.h"
@interface PhotoCollectionVC ()
{
    CustomPhotoManager *_photoManager;
}
@property (weak, nonatomic) IBOutlet UIView *mPhotoView;
@property (weak, nonatomic) IBOutlet UIView *mRightPhotoView;
@property (weak, nonatomic) IBOutlet UILabel *mCountLable;

@end

@implementation PhotoCollectionVC
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_photoManager startTakePhoto];
    [self changePhotosCount];
}
- (void)viewDidLoad {
    [super viewDidLoad];
     _photoManager = [[CustomPhotoManager alloc] init];
    [_photoManager initializeCameraWithPreview:self.mPhotoView ];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changePhotosCount) name:@"ChangePhotosCount" object:nil ];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_photoManager StopTakePhoto];
}
- (IBAction)BtnClick:(UIButton *)sender {
    switch (sender.tag) {
        case 1000:
            //[self.navigationController popViewControllerAnimated:YES];
            [_photoManager setFlashModeState:KFlashFocusAuto];
            break;
        case 1001:
            [_photoManager takePhoto];
            break;
        case 1002:{
        }
        case 1004:{   //转换摄像头
            [_photoManager switchCamera];
        }
        case 1005:{   //闪光灯
         //   KFlashLightOpen,//开启
         //   KFlashLightAuto,//自动
         //   KNoFlashLight//不可用
            [_photoManager setFlashLightState:KFlashLightAuto];
        }
            break;
        default:
            break;
    }
}
-(void)changePhotosCount{
    self.mCountLable.text = [NSString stringWithFormat:@"%lu",(unsigned long)[[_photoManager getImagesArrary]count ] ];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
