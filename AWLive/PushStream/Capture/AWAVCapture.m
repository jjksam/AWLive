/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://blog.csdn.net/hard_man/
 */

#import "AWAVCapture.h"
#import "AWEncoderManager.h"

__weak static AWAVCapture *sAWAVCapture = nil;

extern void aw_rtmp_state_changed_cb_in_oc(aw_rtmp_state old_state, aw_rtmp_state new_state){
    NSLog(@"[OC] rtmp state changed from(%s), to(%s)", aw_rtmp_state_description(old_state), aw_rtmp_state_description(new_state));
    dispatch_async(dispatch_get_main_queue(), ^{
        [sAWAVCapture.stateDelegate avCapture:sAWAVCapture stateChangeFrom:old_state toState:new_state];
    });
}

@interface AWAVCapture()
//编码队列，发送队列
@property (nonatomic, strong) dispatch_queue_t encodeSampleQueue;
@property (nonatomic, strong) dispatch_queue_t sendSampleQueue;
// 是否发送了 metadata
@property (nonatomic, unsafe_unretained) BOOL isMetaDataSent;
//是否已发送了sps/pps
@property (nonatomic, unsafe_unretained) BOOL isSpsPpsAndAudioSpecificConfigSent;

//编码管理
@property (nonatomic, strong) AWEncoderManager *encoderManager;

//进入后台后，不推视频流
@property (nonatomic, unsafe_unretained) BOOL inBackground;
@end

@implementation AWAVCapture

- (void)setPreview:(UIView *)preview {
    _preview = preview;
}

- (dispatch_queue_t)encodeSampleQueue{
    if (!_encodeSampleQueue) {
        _encodeSampleQueue = dispatch_queue_create("aw.encodesample.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _encodeSampleQueue;
}

- (dispatch_queue_t)sendSampleQueue{
    if (!_sendSampleQueue) {
        _sendSampleQueue = dispatch_queue_create("aw.sendsample.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _sendSampleQueue;
}

- (AWEncoderManager *)encoderManager{
    if (!_encoderManager) {
        _encoderManager = [[AWEncoderManager alloc] init];
        //设置编码器类型
        _encoderManager.audioEncoderType = self.audioEncoderType;
        _encoderManager.videoEncoderType = self.videoEncoderType;
    }
    return _encoderManager;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"please call initWithVideoConfig:audioConfig to init" reason:nil userInfo:nil];
}

- (instancetype)initWithVideoConfig:(AWVideoConfig *)videoConfig audioConfig:(AWAudioConfig *)audioConfig{
    self = [super init];
    if (self) {
        self.videoConfig = videoConfig;
        self.audioConfig = audioConfig;
        sAWAVCapture = self;
        [self onInit];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)onInit{}

- (void)willEnterForeground{
    self.inBackground = NO;
}

- (void)didEnterBackground{
    self.inBackground = YES;
}

//修改fps
- (void)updateFps:(NSInteger) fps{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *vDevice in videoDevices) {
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        if (maxRate >= fps) {
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}

- (BOOL)startCaptureWithRtmpUrl:(NSString *)rtmpUrl{
    if (!rtmpUrl || rtmpUrl.length < 8) {
        NSLog(@"rtmpUrl is nil when start capture");
        return NO;
    }
    
    if (!self.videoConfig && !self.audioConfig) {
        NSLog(@"one of videoConfig and audioConfig must be NON-NULL");
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //先开启encoder
        [weakSelf.encoderManager openWithAudioConfig:weakSelf.audioConfig videoConfig:weakSelf.videoConfig];
        //再打开rtmp
        int retcode = aw_streamer_open(rtmpUrl.UTF8String, aw_rtmp_state_changed_cb_in_oc);
        
        if(retcode){
            weakSelf.isCapturing = YES;
        }else{
            NSLog(@"startCapture rtmpOpen error!!! retcode=%d", retcode);
            [weakSelf stopCapture];
        }
    });
    return YES;
}

- (void)stopCapture{
    self.isCapturing = NO;
    self.isMetaDataSent = NO;
    self.isSpsPpsAndAudioSpecificConfigSent = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.sendSampleQueue, ^{
        aw_streamer_close();
    });
    dispatch_sync(self.encodeSampleQueue, ^{
        [weakSelf.encoderManager close];
    });
}

- (void)switchCamera {
}

- (void)switchBeautyFace {

}

- (void)onStopCapture {
    
}

- (void)onStartCapture {
    
}

- (void)setisCapturing:(BOOL)isCapturing{
    if (_isCapturing == isCapturing) {
        return;
    }
    
    if (!isCapturing) {
        [self onStopCapture];
    }else{
        [self onStartCapture];
    }
    
    _isCapturing = isCapturing;
}

//发送数据
- (void)sendVideoSampleBuffer:(CMSampleBufferRef) sampleBuffer toEncodeQueue:(dispatch_queue_t) encodeQueue toSendQueue:(dispatch_queue_t) sendQueue{
    if (_inBackground) {
        return;
    }
    CFRetain(sampleBuffer);
    __weak typeof(self) weakSelf = self;
    dispatch_async(encodeQueue, ^{
        if (weakSelf.isCapturing) {
            aw_flv_video_tag *video_tag = [weakSelf.encoderManager.videoEncoder encodeVideoSampleBufToFlvTag:sampleBuffer];
            [weakSelf sendFlvVideoTag:video_tag toSendQueue:sendQueue];
        }
        CFRelease(sampleBuffer);
    });
}

- (void)sendAudioSampleBuffer:(CMSampleBufferRef) sampleBuffer toEncodeQueue:(dispatch_queue_t) encodeQueue toSendQueue:(dispatch_queue_t) sendQueue{
    CFRetain(sampleBuffer);
    __weak typeof(self) weakSelf = self;
    dispatch_async(encodeQueue, ^{
        if (weakSelf.isCapturing) {
            aw_flv_audio_tag *audio_tag = [weakSelf.encoderManager.audioEncoder encodeAudioSampleBufToFlvTag:sampleBuffer];
            [weakSelf sendFlvAudioTag:audio_tag toSendQueue:sendQueue];
        }
        CFRelease(sampleBuffer);
    });
}

- (void)sendVideoYuvData:(NSData *)yuvData toEncodeQueue:(dispatch_queue_t) encodeQueue toSendQueue:(dispatch_queue_t) sendQueue{
    if (_inBackground) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(encodeQueue, ^{
        if (weakSelf.isCapturing) {
            NSData *rotatedData = [weakSelf.encoderManager.videoEncoder rotateNV12Data:yuvData];
            aw_flv_video_tag *video_tag = [weakSelf.encoderManager.videoEncoder encodeYUVDataToFlvTag:rotatedData];
            [weakSelf sendFlvVideoTag:video_tag toSendQueue:sendQueue];
        }
    });
}

- (void)sendAudioPcmData:(NSData *)pcmData toEncodeQueue:(dispatch_queue_t) encodeQueue toSendQueue:(dispatch_queue_t) sendQueue{
    __weak typeof(self) weakSelf = self;
    dispatch_async(encodeQueue, ^{
        if (weakSelf.isCapturing) {
            aw_flv_audio_tag *audio_tag = [weakSelf.encoderManager.audioEncoder encodePCMDataToFlvTag:pcmData];
            [weakSelf sendFlvAudioTag:audio_tag toSendQueue:sendQueue];
        }
    });
}

- (void)sendFlvVideoTag:(aw_flv_video_tag *)video_tag toSendQueue:(dispatch_queue_t) sendQueue{
    if (_inBackground) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    if (video_tag) {
        dispatch_async(sendQueue, ^{
            if(weakSelf.isCapturing){
                if (!weakSelf.isMetaDataSent) {
                    [weakSelf sendMetaDataToSendQueue:sendQueue];
                } else if (!weakSelf.isSpsPpsAndAudioSpecificConfigSent) {
                    [weakSelf sendSpsPpsAndAudioSpecificConfigTagToSendQueue:sendQueue];
                } else {
                    aw_streamer_send_video_data(video_tag);
                }
            }
        });
    }
}

- (void)sendFlvAudioTag:(aw_flv_audio_tag *)audio_tag toSendQueue:(dispatch_queue_t) sendQueue{
    __weak typeof(self) weakSelf = self;
    if(audio_tag){
        dispatch_async(sendQueue, ^{
            if(weakSelf.isCapturing){
                if (!weakSelf.isMetaDataSent) {
                    [weakSelf sendMetaDataToSendQueue:sendQueue];
                } else if (!weakSelf.isSpsPpsAndAudioSpecificConfigSent) {
                    [weakSelf sendSpsPpsAndAudioSpecificConfigTagToSendQueue:sendQueue];
                } else {
                    aw_streamer_send_audio_data(audio_tag);
                }
            }
        });
    }
}

- (void)sendMetaDataToSendQueue:(dispatch_queue_t)sendQueue {
    if (self.isMetaDataSent) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(sendQueue, ^{
        if (!weakSelf.isCapturing || weakSelf.isMetaDataSent) {
            return;
        }
        // dataFrame
        aw_flv_script_tag *scriptTag = [weakSelf.encoderManager.videoEncoder createScriptDataTag];
        if (scriptTag) {
            scriptTag->duration = 0; // live don't have duration
            if (self.videoConfig.orientation == UIInterfaceOrientationPortrait) {
                scriptTag->width = self.videoConfig.width;
                scriptTag->height = self.videoConfig.height;
            } else {
                scriptTag->width = self.videoConfig.height;
                scriptTag->height = self.videoConfig.width;
            }
            scriptTag->video_data_rate = self.videoConfig.bitrate / 1000.0;
            scriptTag->frame_rate = self.videoConfig.fps;
            scriptTag->v_frame_rate = self.videoConfig.fps;
            scriptTag->a_sample_rate = self.audioConfig.sampleRate;
            scriptTag->a_sample_size = self.audioConfig.sampleSize;
            scriptTag->file_size = 0;
        }
        if (scriptTag) {
            aw_streamer_send_meta_data(scriptTag);
        }
        weakSelf.isMetaDataSent = TRUE;
        
        aw_log("[D] is meta data sent=%d", weakSelf.isMetaDataSent);
    });
}

- (void)sendSpsPpsAndAudioSpecificConfigTagToSendQueue:(dispatch_queue_t) sendQueue{
    if (self.isSpsPpsAndAudioSpecificConfigSent) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(sendQueue, ^{
        if (!weakSelf.isCapturing || weakSelf.isSpsPpsAndAudioSpecificConfigSent) {
            return;
        }
        //video sps pps tag
        aw_flv_video_tag *spsPpsTag = [weakSelf.encoderManager.videoEncoder createSpsPpsFlvTag];
        if (spsPpsTag) {
            aw_streamer_send_video_sps_pps_tag(spsPpsTag);
        }
        //audio specific config tag
        aw_flv_audio_tag *audioSpecificConfigTag = [weakSelf.encoderManager.audioEncoder createAudioSpecificConfigFlvTag];
        if (audioSpecificConfigTag) {
            aw_streamer_send_audio_specific_config_tag(audioSpecificConfigTag);
        }
        weakSelf.isSpsPpsAndAudioSpecificConfigSent = spsPpsTag || audioSpecificConfigTag;
        
        aw_log("[D] is sps pps and audio sepcific config sent=%d", weakSelf.isSpsPpsAndAudioSpecificConfigSent);
    });
}

//使用rtmp协议发送数据
- (void)sendVideoSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    [self sendVideoSampleBuffer:sampleBuffer toEncodeQueue:self.encodeSampleQueue toSendQueue:self.sendSampleQueue];
}

- (void)sendAudioSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    [self sendAudioSampleBuffer:sampleBuffer toEncodeQueue:self.encodeSampleQueue toSendQueue:self.sendSampleQueue];
}

- (void)sendVideoYuvData:(NSData *)videoData{
    [self sendVideoYuvData:(NSData *)videoData toEncodeQueue:self.encodeSampleQueue toSendQueue:self.sendSampleQueue];
}
- (void)sendAudioPcmData:(NSData *)audioData{
    [self sendAudioPcmData:audioData toEncodeQueue:self.encodeSampleQueue toSendQueue:self.sendSampleQueue];
}

- (void)sendFlvVideoTag:(aw_flv_video_tag *)flvVideoTag{
    [self sendFlvVideoTag:flvVideoTag toSendQueue:self.sendSampleQueue];
}

- (void)sendFlvAudioTag:(aw_flv_audio_tag *)flvAudioTag{
    [self sendFlvAudioTag:flvAudioTag toSendQueue:self.sendSampleQueue];
}

- (NSString *)captureSessionPreset{
    NSString *captureSessionPreset = nil;
//    if(self.videoConfig.width == 480 && self.videoConfig.height == 640){
//        captureSessionPreset = AVCaptureSessionPreset640x480;
//    }else if(self.videoConfig.width == 540 && self.videoConfig.height == 960){
//        captureSessionPreset = AVCaptureSessionPresetiFrame960x540;
//    }else if(self.videoConfig.width == 720 && self.videoConfig.height == 1280){
//        captureSessionPreset = AVCaptureSessionPreset1280x720;
//    }
    
//    AVCaptureSessionPresetMedium : 480x360
    if (self.videoConfig.width == 240 && self.videoConfig.height == 320) {
#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
        captureSessionPreset = AVCaptureSessionPreset320x240; // iPhone do not support this resolution
#else
        captureSessionPreset = AVCaptureSessionPresetLow; // fallback
#endif
    } else if (self.videoConfig.width == 480 && self.videoConfig.height == 640) {
        captureSessionPreset = AVCaptureSessionPreset640x480;
    } else if (self.videoConfig.width == 540 && self.videoConfig.height == 960) {
        captureSessionPreset = AVCaptureSessionPresetiFrame960x540;
    } else if (self.videoConfig.width == 720 && self.videoConfig.height == 1280) {
        captureSessionPreset = AVCaptureSessionPreset1280x720;
    } else if (self.videoConfig.width == 1080 && self.videoConfig.height == 1920) {
#if TARGET_OS_IPHONE
        captureSessionPreset = AVCaptureSessionPreset1920x1080;
#endif
    } else if (self.videoConfig.width == 360 && self.videoConfig.height == 640) {
        captureSessionPreset = AVCaptureSessionPreset640x480;
    }
    return captureSessionPreset;
}

@end
