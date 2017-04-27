//
//  RSCLiveApi.h
//  AWLive
//
//  Created by jjk on 2017/3/24.
//
//

#import <UIKit/UIKit.h>

@protocol RSCDeviceEventDelegate;
@protocol RSCLivePublisherDelegate;

typedef enum {
    RSCAVConfigPreset_Verylow  = 0,
    RSCAVConfigPreset_Low      = 1,
    RSCAVConfigPreset_Generic  = 2,
    RSCAVConfigPreset_High     = 3,    ///< 手机端直播建议使用High配置，效果最优
    RSCAVConfigPreset_Veryhigh = 4
} RSCAVConfigPreset;

/// \brief 推流视频配置
@interface RSCAVConfig : NSObject

+ (instancetype)presetConfigOf:(RSCAVConfigPreset)preset;

@property (assign) CGSize videoEncodeResolution;    ///< 视频编码输出分辨率
@property (assign) CGSize videoCaptureResolution;   ///< 视频采集分辨率
@property (assign) int fps;                         ///< 视频帧率
@property (assign) int bitrate;                     ///< 视频码率

@end

typedef enum {
    RSCVideoViewModeScaleAspectFit     = 0,    ///< 等比缩放，可能有黑边
    RSCVideoViewModeScaleAspectFill    = 1,    ///< 等比缩放填充整View，可能有部分被裁减
    RSCVideoViewModeScaleToFill        = 2,    ///< 填充整个View
} RSCVideoViewMode;

@interface RSCLiveApi : NSObject

@property (assign) UIInterfaceOrientation appOrientation;
@property (nonatomic, weak) id<RSCLivePublisherDelegate> delegate;

+ (NSString *)version;
/// \brief 调试信息开关
/// \desc 建议在调试阶段打开此开关，方便调试。默认关闭
/// \param bOnVerbose 是否使用测试环境
+ (void)setVerbose:(bool)bOnVerbose;

// * device

/// \brief 音视频设备错误通知回调
/// \param deviceEventDelegate 音视频设备错误通知回调协议
/// \return true 成功，false 失败
- (bool)setDeviceEventDelegate:(id<RSCDeviceEventDelegate>)deviceEventDelegate;

- (bool)setPublisherDelegate:(id<RSCLivePublisherDelegate>)publisherDelegate;

// * live publish
/// \brief 设置本地预览视图
/// \param[in] view 用于渲染本地预览视频的视图
/// \return true 成功，false 失败
- (bool)setPreviewView:(UIView *)view;

/// \brief 启动本地预览
/// \return true 成功，false 失败
- (bool)startPreview;

/// \brief 结束本地预览
/// \return true 成功，false 失败
- (bool)stopPreview;

/// \brief 开始直播
/// \param[in] pushUrl 推流地址
/// \return true，成功，等待 - (void)onPublishStateChangeFrom:(int)fromState toState:(int)toState;] 回调，false 失败
- (bool)startPublishingWithUrl:(NSString *)pushUrl;

/// \brief 停止直播
/// \return true 成功，false 失败
- (bool)stopPublishing;

/// \brief 开关硬件编码
/// \param bRequire 开关
/// \note ！！！打开硬编硬解开关需后台可控，避免碰到版本升级或者硬件升级时出现硬编硬解失败的问题
+ (bool)requireHardwareEncoder:(bool)bRequire;

/// \brief 设置视频配置
/// \param config 配置参数
/// \return true 成功，false 失败
- (bool)setAVConfig:(RSCAVConfig *)config;

#if TARGET_OS_IPHONE
/// \brief 设置手机姿势，用于校正主播输出视频朝向
/// \param orientation 手机姿势
- (void)setAppOrientation:(UIInterfaceOrientation)orientation;
#endif

/// \brief 主播方开启美颜功能
/// \param feature 美颜特性
/// \return bool true: 成功；false: 失败
- (bool)enableBeautifying:(int)feature;

/// \brief 设置本地预览视频View的模式
/// \param mode 模式，详见ZegoVideoViewMode
/// \return true:调用成功；false:调用失败
- (bool)setPreviewViewMode:(RSCVideoViewMode)mode;

///// \brief 设置预览渲染朝向
///// \param rotate 旋转角度
///// \return true 成功，false 失败
///// \note 使用setAppOrientation 替代
//- (bool)setPreviewRotation:(int)rotate;

/// \brief 是否开启码率控制（在带宽不足的情况下码率自动适应当前带宽)
/// \param enable true 启用，false 不启用
/// \return true 成功，否则失败
- (bool)enableRateControl:(bool)enable;

/// \brief 设置是否使用前置摄像头
/// \param bFront 使用前置摄像头
/// \return true:调用成功；false:调用失败
- (bool)setFrontCam:(bool)bFront;

/// \brief 开启关闭麦克风
/// \param bEnable true打开，false关闭
/// \return true:调用成功；false:调用失败
- (bool)enableMic:(bool)bEnable;

/// \brief 开启关闭视频采集
/// \param bEnable true打开，false关闭
/// \return true:调用成功；false:调用失败
- (bool)enableCamera:(bool)bEnable;

/// \brief 开关手电筒
/// \param bEnable true打开，false关闭
/// \return true：成功；false:失败
- (bool)enableTorch:(bool) bEnable;

//- (bool)takePreviewSnapshot:(RSCSnapshotCompletionBlock)blk;

// 改变输入增益 范围float 0.0~1.0
- (bool)changeGainValue:(float)value;

@end

@protocol RSCLivePublisherDelegate <NSObject>

/// \brief 推流状态更新
/// \param[in] fromState 状态码
/// \param[in] toState 流ID
- (void)onPublishStateChangeFrom:(int)fromState toState:(int)toState;

@optional

/// \brief 发布质量更新
/// \param quality 0 ~ 3 分别对应优良中差
/// \param streamID 发布流ID
/// \param fps 帧率(frame rate)
/// \param kbs 码率(bit rate) kb/s
- (void)onPublishQualityUpdate:(int)quality stream:(NSString *)streamID videoFPS:(double)fps videoBitrate:(double)kbs;

/// \brief 采集视频的宽度和高度变化通知
/// \param size 视频大小
- (void)onCaptureVideoSizeChangedTo:(CGSize)size;

/// \brief 混音数据输入回调
/// \param pData 数据缓存起始地址
/// \param pDataLen [in] 缓冲区长度；[out]实际填充长度，必须为 0 或是缓冲区长度，代表有无混音数据
/// \param pSampleRate 混音数据采样率
/// \param pChannelCount 混音数据声道数
/// \note 混音数据 bit depth 必须为 16
- (void)onAuxCallback:(void *)pData dataLen:(int *)pDataLen sampleRate:(int *)pSampleRate channelCount:(int *)pChannelCount;
@end

@protocol RSCDeviceEventDelegate <NSObject>

- (void)rsc_onDevice:(NSString *)deviceName error:(int)errorCode;

@end
