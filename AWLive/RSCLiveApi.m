//
//  RSCLiveApi.m
//  AWLive
//
//  Created by jjk on 2017/3/24.
//
//

#import "RSCLiveApi.h"
#import "AWAVCaptureManager.h"
@interface RSCLiveApi () <AWAVCaptureDelegate>

@property (nonatomic, strong) AWAVCaptureManager *captureManager;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) RSCAVConfig *avConfig;
@property (nonatomic, strong) AVAudioSession *audioSession;

@end

@implementation RSCLiveApi

+ (NSString *)version {
    return @"1.0.0";
}

#pragma mark 懒加载
- (AWAVCaptureManager *)captureManager {
    if (!_captureManager) {
        _captureManager = [[AWAVCaptureManager alloc] init];
        
//下面的3个类型必须设置，否则获取不到AVCapture
//        _captureManager.captureType = AWAVCaptureTypeGPUImage; // GPUImage过滤，iPhone 6 CPU 60%以上
        _captureManager.captureType = AWAVCaptureTypeSystem; // 系统视频捕获推流, iPhone 6 CPU 40%左右
        _captureManager.audioEncoderType = AWAudioEncoderTypeHWAACLC;
        _captureManager.videoEncoderType = AWVideoEncoderTypeHWH264;
//        _captureManager.audioEncoderType = AWAudioEncoderTypeSWFAAC; // 软编码，iPhone 5需要使用声音软编码
//        _captureManager.videoEncoderType = AWVideoEncoderTypeSWX264; // 软编码，停止推流会崩溃, iPhone 5/5s没法用硬件加速
        _captureManager.audioConfig = [[AWAudioConfig alloc] init];
        _captureManager.videoConfig = [[AWVideoConfig alloc] init];
        
        // 竖屏推流
        _captureManager.videoConfig.orientation = self.appOrientation;
        // 横屏推流
//        _captureManager.videoConfig.orientation = UIInterfaceOrientationLandscapeRight;
    }
    return _captureManager;
}

- (AWAVCapture *)avCapture {
    AWAVCapture *capture = self.captureManager.avCapture;
    capture.stateDelegate = self;
    return capture;
}

/// \brief 设置是否使用前置摄像头
/// \param bFront 使用前置摄像头
/// \return true:调用成功；false:调用失败
- (bool)setFrontCam:(bool)bFront {
    [self.avCapture switchCamera];
    return true;
}

- (bool)setPreviewView:(UIView *)view {
    if (view == nil)
        return false;
    self.preview = view;
    return true;
}

- (bool)startPreview {
    [self.avCapture setPreview:self.preview];
    return true;
}

- (bool)changeGainValue:(float)value {
    CGFloat gain = value;
    NSError* error;
    self.audioSession = [AVAudioSession sharedInstance];
    if (self.audioSession.isInputGainSettable) {
        BOOL success = [self.audioSession setInputGain:gain
                                                 error:&error];
        if (!success) {
            return false;
        } //error handling
    } else {
        NSLog(@"ios6 - cannot set input gain");
        return false;
    }
    return true;
}

- (bool)startPublishingWithUrl:(NSString *)pushUrl {
    bool ret = [self.avCapture startCaptureWithRtmpUrl:pushUrl];
    return ret;
}

/// \brief 停止直播
/// \return true 成功，false 失败
- (bool)stopPublishing {
    if (self.avCapture.isCapturing) {
        [self.avCapture stopCapture];
    }
    return true;
}

#pragma mark 事件
-(void)avCapture:(AWAVCapture *)capture stateChangeFrom:(aw_rtmp_state)fromState toState:(aw_rtmp_state)toState{
    if ([self.delegate respondsToSelector:@selector(onPublishStateChangeFrom:toState:)]) {
        [self.delegate onPublishStateChangeFrom:fromState toState:toState];
    }
    switch (toState) {
        case aw_rtmp_state_idle: {
//            self.startBtn.enabled = YES;
//            [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
//            self.stateText = @"未连接";
            break;
        }
        case aw_rtmp_state_connecting: {
//            self.startBtn.enabled = NO;
//            self.stateText = @"连接中";
            break;
        }
        case aw_rtmp_state_opened: {
//            self.startBtn.enabled = YES;
//            self.stateText = @"正在直播";
            break;
        }
        case aw_rtmp_state_connected: {
//            self.stateText = @"连接成功";
            break;
        }
        case aw_rtmp_state_closed: {
//            self.startBtn.enabled = YES;
//            self.stateText = @"已关闭";
            break;
        }
        case aw_rtmp_state_error_write: {
//            self.stateText = @"写入错误";
            break;
        }
        case aw_rtmp_state_error_open: {
//            self.stateText = @"连接错误";
//            self.startBtn.enabled = YES;
            break;
        }
        case aw_rtmp_state_error_net: {
//            self.stateText = @"网络不给力";
//            self.startBtn.enabled = YES;
            break;
        }
    }
}


@end
