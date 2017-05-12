//
//  PublishViewController.m
//  AWLive
//
//  Created by jjk on 2017/3/21.
//
//

#import <AVFoundation/AVFoundation.h>
#import "PublishViewController.h"
#import "RSCLiveApi.h"
#import "PureLayout.h"
#import "aw_rtmp.h" // should hide


@interface PublishViewController () <RSCLivePublisherDelegate> {
    AudioQueueRef m_queue;
    dispatch_source_t timer;
}
@property (nonatomic, strong) RSCLiveApi *api;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UILabel *stateText;

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) AVAudioSession *audioSession;

@property (assign) BOOL isPublishing;
@property (assign) BOOL useFrontCamera;

@end

@implementation PublishViewController

- (void)dealloc {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
//    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"inputGain"];
}

static void AudioInputCallback(
                               void* inUserData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime,
                               UInt32 inNumberPacketDescriptions,
                               const AudioStreamPacketDescription *inPacketDescs)
{
    // 録音はしないので未実装
}

static void MyAudioQueuePropertyListenerProc(void *pParam, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
//    CAudioQueuePlayer* pPlayer = (CAudioQueuePlayer *)pParam;
    
    switch (inID) {
        case kAudioQueueProperty_IsRunning:
        {
            UInt32 bRunning;
            UInt32 size = sizeof(bRunning);
            OSStatus result = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &bRunning, &size);
            if ((result == noErr) && (!bRunning))
            {
                NSLog(@"player stoped\n");
            }
        }
            break;
        case kAudioQueueProperty_CurrentLevelMeter:
        {
            // レベルを取得
            AudioQueueLevelMeterState levelMeter;
            UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
            OSStatus result = AudioQueueGetProperty(inAQ, kAudioQueueProperty_CurrentLevelMeter, &levelMeter, &levelMeterSize);
            if (result == noErr)
            {
                // 最大レベル、平均レベルを表示
                NSLog(@"MyAudioQueuePropertyListenerProc callback");
                NSLog(@"peakPower: %@", [NSString stringWithFormat:@"%.2f", levelMeter.mPeakPower]);
                NSLog(@"averagePower: %@", [NSString stringWithFormat:@"%.2f", levelMeter.mAveragePower]);
                printf("player stoped\n");
            }
            break;
        }
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (UIInterfaceOrientationIsLandscape(self.orientation)) {
        CGFloat dx = [UIScreen mainScreen].bounds.size.width / 2 - [UIScreen mainScreen].bounds.size.height / 2;
        CGFloat dy = [UIScreen mainScreen].bounds.size.width / 2 - [UIScreen mainScreen].bounds.size.height / 2;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-dx, -dy);
        self.preview.transform = CGAffineTransformRotate(transform, -M_PI_2);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // レベルの監視を停止する
    dispatch_source_cancel(timer);
//    [_timer invalidate];
    [self stopUpdatingVolume];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.useFrontCamera = YES;
    // Do any additional setup after loading the view.
    _preview = [UIView new];
    [self.view addSubview:_preview];
    [self.view sendSubviewToBack:_preview];
    [_preview autoPinEdgesToSuperviewEdges];
    [_preview layoutIfNeeded];
    
    UIButton *closeButton = [[UIButton alloc] initForAutoLayout];
    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
//    closeButton.layer.borderColor = [UIColor blackColor].CGColor;
//    closeButton.layer.borderWidth = 1;
    closeButton.backgroundColor = [UIColor blackColor];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    [closeButton autoSetDimensionsToSize:CGSizeMake(60, 44)];
    [closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
    [closeButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:30];
    
    self.startBtn = [[UIButton alloc] initForAutoLayout];
    [self.startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    self.startBtn.backgroundColor = [UIColor blackColor];
    [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
    [self.startBtn addTarget:self action:@selector(onStartClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startBtn];
    
    [self.startBtn autoSetDimensionsToSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 80, 40)];
    [self.startBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:30];
    [self.startBtn autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    self.stateText = [[UILabel alloc] initForAutoLayout];
    self.stateText.textColor = [UIColor whiteColor];
    self.stateText.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.stateText];
    
    [self.stateText autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
    [self.stateText autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
    
    UIButton *switchCamera = [[UIButton alloc] initForAutoLayout];
    [switchCamera setBackgroundColor:[UIColor blackColor]];
    [switchCamera setTitle:@"switch cam" forState:UIControlStateNormal];
    [switchCamera addTarget:self action:@selector(onSwitchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:switchCamera];
    
    [switchCamera autoSetDimensionsToSize:CGSizeMake(100, 44)];
    [switchCamera autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:8];
    [switchCamera autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:100];
    
    
    _progressView = [[UIProgressView alloc] initForAutoLayout];
    [_progressView setProgressTintColor:[UIColor greenColor]];
    [_progressView setTrackTintColor:[UIColor blackColor]];
    [_progressView setTintColor:[UIColor blackColor]];
    [_progressView setProgress:0];
    [self.view addSubview:_progressView];
    
    [_progressView autoSetDimensionsToSize:CGSizeMake(100, 10)];
    [_progressView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:8];
    [_progressView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:30];
    
    // 音を拾う
    [self startUpdatingVolume];
/*
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] addObserver:self
                                      forKeyPath:@"inputGain"
                                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                         context:(void *)[AVAudioSession sharedInstance]];
    [[AVAudioSession sharedInstance] addObserver:self
                                      forKeyPath:@"outputVolume"
                                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                         context:(void *)[AVAudioSession sharedInstance]];
 */
    NSError* error;
    self.audioSession = [AVAudioSession sharedInstance];
    
    if (self.audioSession.isInputGainSettable) {
        [self.audioSession addObserver:self forKeyPath:@"inputGain" options:0 context:nil];
        BOOL success = [self.audioSession setInputGain:0.5
                                                 error:&error];
        if (!success) {
//            return false;
        } //error handling
    } else {
        NSLog(@"ios6 - cannot set input gain");
//        return false;
    }
    if (UIInterfaceOrientationIsLandscape(self.orientation)) {
        NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
        [[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
        
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
    } else {
        NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
        [[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
        
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
    }
    _api = [[RSCLiveApi alloc] init];
    _api.delegate = self;
    [_api setFrontCam:self.useFrontCamera];
    [_api setAppOrientation:self.orientation];
    [_api setPreviewView:_preview];
    [_api startPreview];
}


- (void)startUpdatingVolume
{
    // 記録するデータフォーマットを決める
    AudioStreamBasicDescription dataFormat;
    dataFormat.mSampleRate = 44100.0f;
    dataFormat.mFormatID = kAudioFormatLinearPCM;
    dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    dataFormat.mBytesPerPacket = 2;
    dataFormat.mFramesPerPacket = 1;
    dataFormat.mBytesPerFrame = 2;
    dataFormat.mChannelsPerFrame = 1;
    dataFormat.mBitsPerChannel = 16;
    dataFormat.mReserved = 0;
    
    // レベルの監視を開始する
    AudioQueueNewInput(&dataFormat, AudioInputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &m_queue);
    AudioQueueStart(m_queue, NULL);
    
    // レベルメータを有効化する
    UInt32 enabledLevelMeter = true;
    AudioQueueSetProperty(m_queue, kAudioQueueProperty_EnableLevelMetering, &enabledLevelMeter, sizeof(UInt32));
    
    // add level meter property listener
    OSStatus ecode;
    // kAudioQueueProperty_CurrentLevelMeterDB The member values in the structure are in decibels. 分贝值表示
    ecode = AudioQueueAddPropertyListener(m_queue, kAudioQueueProperty_CurrentLevelMeter, MyAudioQueuePropertyListenerProc, (__bridge void *)(self));
    ecode = AudioQueueAddPropertyListener(m_queue, kAudioQueueProperty_IsRunning, MyAudioQueuePropertyListenerProc, (__bridge void *)(self));

    // 定期的にレベルメータを監視する
    // timer
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.04 * NSEC_PER_SEC, 0.04 * NSEC_PER_SEC);
    __weak typeof (self) wself = self;
    dispatch_source_set_event_handler(timer, ^{
        [wself detectVolume:nil];
    });
    dispatch_resume(timer);
}

- (void)stopUpdatingVolume
{
    // キューを空にして停止
    AudioQueueFlush(m_queue);
    AudioQueueStop(m_queue, NO);
    AudioQueueDispose(m_queue, YES);
}

- (void)detectVolume:(NSTimer *)timer
{
    // レベルを取得
    AudioQueueLevelMeterState levelMeter;
    UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(m_queue, kAudioQueueProperty_CurrentLevelMeter, &levelMeter, &levelMeterSize);
    
    // 最大レベル、平均レベルを表示
//    NSLog(@"peakPower: %@", [NSString stringWithFormat:@"%.2f", levelMeter.mPeakPower]);
//    NSLog(@"averagePower: %@", [NSString stringWithFormat:@"%.2f", levelMeter.mAveragePower]);
    self.progressView.progress = levelMeter.mAveragePower;
    [self.progressView setNeedsDisplay];
//    self.peakTextField.text = [NSString stringWithFormat:@"%.2f", levelMeter.mPeakPower];
//    self.averageTextField.text = [NSString stringWithFormat:@"%.2f", levelMeter.mAveragePower];
    
    // mPeakPowerが -1.0 以上なら "LOUD!!" と表示
//    self.loudLabel.hidden = (levelMeter.mPeakPower >= -1.0f) ? NO : YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == (__bridge void *)[AVAudioSession sharedInstance]) {
           float newValue = [[change objectForKey:@"new"] floatValue];
           float oldValue = [[change objectForKey:@"old"] floatValue];
       }
    if ([keyPath isEqualToString:@"inputGain"]) {
        if (object == self.audioSession) {
            NSLog(@"inputGain: %0.1f", self.audioSession.inputGain);
            [self.progressView setProgress:self.audioSession.inputGain];
        }
    }
}

- (void)onSwitchCamera {
    self.useFrontCamera = !self.useFrontCamera;
    [_api setFrontCam:self.useFrontCamera];
}

- (void)onClose {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [_api stopPublishing];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onStartClick {
    if (self.isPublishing) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.api stopPublishing];
        self.isPublishing = NO;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self.api startPublishingWithUrl:self.pushUrl];
        [self.startBtn setTitle:@"停止直播" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIInterfaceOrientationIsPortrait(self.orientation)) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskLandscapeRight;
    }

}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (UIInterfaceOrientationIsPortrait(self.orientation)) {
        return UIInterfaceOrientationPortrait;
    } else {
        return UIInterfaceOrientationLandscapeRight;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (void)onPublishStateChangeFrom:(int)fromState toState:(int)toState {
    switch (toState) {
        case aw_rtmp_state_idle: {
            self.startBtn.enabled = YES;
            [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
            self.stateText.text = @"未连接";
            break;
        }
        case aw_rtmp_state_connecting: {
            self.startBtn.enabled = NO;
            self.stateText.text = @"连接中";
            break;
        }
        case aw_rtmp_state_opened: {
            self.startBtn.enabled = YES;
            self.stateText.text = @"正在直播";
            self.isPublishing = YES;
            break;
        }
        case aw_rtmp_state_connected: {
            self.stateText.text = @"连接成功";
            // should send metadata before sending video/audio packet
            break;
        }
        case aw_rtmp_state_closed: {
            self.startBtn.enabled = YES;
            self.stateText.text = @"已关闭";
            break;
        }
        case aw_rtmp_state_error_write: {
            self.stateText.text = @"写入错误";
            break;
        }
        case aw_rtmp_state_error_open: {
            self.stateText.text = @"连接错误";
            self.startBtn.enabled = YES;
            break;
        }
        case aw_rtmp_state_error_net: {
            self.stateText.text = @"网络不给力";
            self.startBtn.enabled = YES;
            break;
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
