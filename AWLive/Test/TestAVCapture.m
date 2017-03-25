/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://blog.csdn.net/hard_man/
 */

#import "TestAVCapture.h"

#import "AWAVCaptureManager.h"
#import "LandscapeViewController.h"
#import "PureLayout.h"

/*
 测试代码
 */

//请修改此地址
static NSString *sRtmpUrl = @"rtmp://live.roadshowchina.cn/live/123456";

@interface TestVideoCapture ()<AWAVCaptureDelegate>

//按钮
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *switchBtn;

//状态
@property (nonatomic, strong) UILabel *stateLabel;

//预览
@property (nonatomic, strong) UIView *preview;

@property (nonatomic, weak) LandscapeViewController *viewController;

@property (nonatomic, strong) AWAVCaptureManager *captureManager;

@end

@implementation TestVideoCapture

#pragma mark 懒加载
-(AWAVCaptureManager *)captureManager{
    if (!_captureManager) {
        _captureManager = [[AWAVCaptureManager alloc] init];
        
        //下面的3个类型必须设置，否则获取不到AVCapture
//        _captureManager.captureType = AWAVCaptureTypeGPUImage; // GPUImage过滤，iPhone 6 CPU 60%以上
        _captureManager.captureType = AWAVCaptureTypeSystem; // 系统视频捕获推流, iPhone 6 CPU 40%左右
        _captureManager.audioEncoderType = AWAudioEncoderTypeHWAACLC;
        _captureManager.videoEncoderType = AWVideoEncoderTypeHWH264;
//        _captureManager.videoEncoderType = AWVideoEncoderTypeSWX264; // 软编码，停止推流会崩溃
        _captureManager.audioConfig = [[AWAudioConfig alloc] init];
        _captureManager.videoConfig = [[AWVideoConfig alloc] init];
        
        // 竖屏推流
//        _captureManager.videoConfig.orientation = UIInterfaceOrientationPortrait;
        // 横屏推流
        _captureManager.videoConfig.orientation = UIInterfaceOrientationLandscapeRight;
    }
    return _captureManager;
}

- (AWAVCapture *)avCapture {
    AWAVCapture *capture = self.captureManager.avCapture;
    capture.stateDelegate = self;
    return capture;
}

#pragma mark 初始化
-(instancetype) initWithViewController:(UIViewController *)viewCtl{
    if (self = [super init]) {
        self.viewController = (LandscapeViewController *)viewCtl;
        [self createUI];
    }
    return self;
}

- (void)createUI {

    [self.avCapture setPreview:self.viewController.preview];
    
//    self.avCapture.preview.center = self.viewController.preview.center;
    
    self.stateLabel = [[UILabel alloc] initForAutoLayout];
    self.stateText = @"未连接";
    [self.viewController.view addSubview:self.stateLabel];
    
    self.startBtn = [[UIButton alloc] initForAutoLayout];
    [self.startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    self.startBtn.backgroundColor = [UIColor blackColor];
    [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
    [self.startBtn addTarget:self action:@selector(onStartClick) forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:self.startBtn];
    
    self.startBtn.layer.borderWidth = 0.5;
    self.startBtn.layer.borderColor = [[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1] CGColor];
    self.startBtn.layer.cornerRadius = 5;
    
    self.switchBtn = [[UIButton alloc] initForAutoLayout];
    UIImage *switchImage = [self imageWithPath:@"camera_switch.png" scale:2];
    switchImage = [switchImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.switchBtn setImage:switchImage forState:UIControlStateNormal];
    [self.switchBtn setTintColor:[UIColor whiteColor]];
    [self.switchBtn addTarget:self action:@selector(onSwitchClick) forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:self.switchBtn];
    
    UIButton *beautyFace = [[UIButton alloc] initForAutoLayout];
    [beautyFace setTitle:@"美颜" forState:UIControlStateNormal];
    [beautyFace setTintColor:[UIColor whiteColor]];
    [beautyFace addTarget:self action:@selector(onBeautyFace) forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:beautyFace];
}

- (void)onBeautyFace {

}

- (UIImage *)imageWithPath:(NSString *)path scale:(CGFloat)scale {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
    if (imagePath) {
        NSData *imgData = [NSData dataWithContentsOfFile:imagePath];
        if (imgData) {
            UIImage *image = [UIImage imageWithData:imgData scale:scale];
            return image;
        }
    }
    
    return nil;
}

- (void)onLayout {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    [self.stateLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:90];
    [self.stateLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
    
//    self.stateLabel.frame = CGRectMake(30, 130, 100, 30);
    [self.startBtn autoSetDimensionsToSize:CGSizeMake(screenSize.width - 80, 40)];
    [self.startBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:30];
    [self.startBtn autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
//    self.startBtn.frame = CGRectMake(40, screenSize.height - 150 - 40, screenSize.width - 80, 40);
    
    [self.switchBtn autoSetDimensionsToSize:CGSizeMake(self.switchBtn.currentImage.size.width, self.switchBtn.currentImage.size.width)];
    [self.switchBtn autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:90];
    [self.switchBtn autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:30];
    
//    self.switchBtn.frame = CGRectMake(screenSize.width - 30 - self.switchBtn.currentImage.size.width, 130, self.switchBtn.currentImage.size.width, self.switchBtn.currentImage.size.width);
}

-(void) setStateText:(NSString *)stateText{
    NSAttributedString *attributeString = [[NSAttributedString alloc] initWithString:stateText
                                                                          attributes:@{
                                                                                       NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                       NSStrokeColorAttributeName: [UIColor blackColor],
                                                                                       NSStrokeWidthAttributeName: @(-0.5)
                                                                                       }];
    self.stateLabel.attributedText = attributeString;
}

#pragma mark 事件
-(void)avCapture:(AWAVCapture *)capture stateChangeFrom:(aw_rtmp_state)fromState toState:(aw_rtmp_state)toState{
    switch (toState) {
        case aw_rtmp_state_idle: {
            self.startBtn.enabled = YES;
            [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
            self.stateText = @"未连接";
            break;
        }
        case aw_rtmp_state_connecting: {
            self.startBtn.enabled = NO;
            self.stateText = @"连接中";
            break;
        }
        case aw_rtmp_state_opened: {
            self.startBtn.enabled = YES;
            self.stateText = @"正在直播";
            break;
        }
        case aw_rtmp_state_connected: {
            self.stateText = @"连接成功";
            break;
        }
        case aw_rtmp_state_closed: {
            self.startBtn.enabled = YES;
            self.stateText = @"已关闭";
            break;
        }
        case aw_rtmp_state_error_write: {
            self.stateText = @"写入错误";
            break;
        }
        case aw_rtmp_state_error_open: {
            self.stateText = @"连接错误";
            self.startBtn.enabled = YES;
            break;
        }
        case aw_rtmp_state_error_net: {
            self.stateText = @"网络不给力";
            self.startBtn.enabled = YES;
            break;
        }
    }
}

-(void) onStartClick{
    if (self.avCapture.isCapturing) {
        [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
        [self.avCapture stopCapture];
    }else{
        if ([self.avCapture startCaptureWithRtmpUrl:sRtmpUrl]) {
            [self.startBtn setTitle:@"停止直播" forState:UIControlStateNormal];
        }
    }
}

-(void) onSwitchClick{
    [self.avCapture switchCamera];
}

@end
