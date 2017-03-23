/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://blog.csdn.net/hard_man/
 */

#import "AWGPUImageAVCapture.h"
#import <GPUImage/GPUImageFramework.h>
#import "GPUImageBeautifyFilter.h"
#import "AWGPUImageVideoCamera.h"
#import "libyuv.h"

//GPUImage data handler
@interface AWGPUImageAVCaptureDataHandler : GPUImageRawDataOutput< AWGPUImageVideoCameraDelegate>
@property (nonatomic, weak) AWAVCapture *capture;
@end

@implementation AWGPUImageAVCaptureDataHandler

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat capture:(AWAVCapture *)capture
{
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        self.capture = capture;
    }
    return self;
}

-(void)processAudioSample:(CMSampleBufferRef)sampleBuffer{
    if(!self.capture || !self.capture.isCapturing){
        return;
    }
    [self.capture sendAudioSampleBuffer:sampleBuffer];
}

-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    if(!self.capture || !self.capture.isCapturing){
        return;
    }
    //将bgra转为yuv
    //图像宽度
    int width = aw_stride((int)imageSize.width);
    //图像高度
    int height = imageSize.height;
    //宽*高
    int w_x_h = width * height;
    //yuv数据长度 = (宽 * 高) * 3 / 2
    int yuv_len = w_x_h * 3 / 2;
    
    //yuv数据
    uint8_t *yuv_bytes = malloc(yuv_len);
    
    //ARGBToNV12这个函数是libyuv这个第三方库提供的一个将bgra图片转为yuv420格式的一个函数。
    //libyuv是google提供的高性能的图片转码操作。支持大量关于图片的各种高效操作，是视频推流不可缺少的重要组件，你值得拥有。
    [self lockFramebufferForReading];
    ARGBToNV12(self.rawBytesForImage, width * 4, yuv_bytes, width, yuv_bytes + w_x_h, width, width, height);
    [self unlockFramebufferAfterReading];
    
    NSData *yuvData = [NSData dataWithBytesNoCopy:yuv_bytes length:yuv_len];
/* 这里只对输出生效，要渲染GPUImageView才能正确预览，考虑直接不用系统filter
    //现在要把NV12数据放入 CVPixelBufferRef中，因为 硬编码主要调用VTCompressionSessionEncodeFrame函数，此函数不接受yuv数据，但是接受CVPixelBufferRef类型。
    CVPixelBufferRef pixelBuf = NULL;
    //初始化pixelBuf，数据类型是kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange，此类型数据格式同NV12格式相同。
    CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuf);
    
    // Lock address，锁定数据，应该是多线程防止重入操作。
    if(CVPixelBufferLockBaseAddress(pixelBuf, 0) == kCVReturnSuccess){
//        [self onErrorWithCode:AWEncoderErrorCodeLockSampleBaseAddressFailed des:@"encode video lock base address failed"];
        
        //将yuv数据填充到CVPixelBufferRef中
        size_t y_size = aw_stride(width) * height;
        size_t uv_size = y_size / 4;
        uint8_t *yuv_frame = (uint8_t *)yuvData.bytes;
        
        //处理y frame
        uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 0);
        memcpy(y_frame, yuv_frame, y_size);
        
        uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 1);
        memcpy(uv_frame, yuv_frame + y_size, uv_size * 2);
// CIFilter 尝试从这里入手处理
    CIContext *context = [CIContext new];
    CIFilter *filter = [CIFilter filterWithName:@"CIFaceBalance"];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuf];
    [filter setValue:ciImage forKey:kCIInputImageKey];
//    CIImage *resultImage = filter.outputImage;
//    [context render:resultImage toCVPixelBuffer:pixelBuf];


    CIImage *resultImage = [filter.outputImage imageByApplyingFilter:@"CIColorMonochrome" withInputParameters:@{}];
//    NSDictionary *options = @{};
//    NSArray *adjustments = [ciImage autoAdjustmentFiltersWithOptions:options];
//    CIImage *resultImage;
//    for (CIFilter *filter in adjustments) {
//        [filter setValue:ciImage forKey:kCIInputImageKey];
//        resultImage = filter.outputImage;
        [context render:resultImage toCVPixelBuffer:pixelBuf];
//    }

        memcpy(yuv_frame, y_frame, y_size);
        memcpy(yuv_frame + y_size, uv_frame, uv_size * 2);
        CVPixelBufferUnlockBaseAddress(pixelBuf, 0);
        CFRelease(pixelBuf);
    }
*/
    [self.capture sendVideoYuvData:yuvData];
}

@end

//GPUImage capture
@interface AWGPUImageAVCapture()
@property (nonatomic, strong) AWGPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;
@property (nonatomic, strong) GPUImageCropFilter *cropFilter;
@property (nonatomic, strong) AWGPUImageAVCaptureDataHandler *dataHandler;
@end

@implementation AWGPUImageAVCapture

#pragma mark 懒加载

-(void)onInit{
    //摄像头
    _videoCamera = [[AWGPUImageVideoCamera alloc] initWithSessionPreset:self.captureSessionPreset cameraPosition:AVCaptureDevicePositionFront];
    //声音
    [_videoCamera addAudioInputsAndOutputs];
    //屏幕方向
    if (self.videoConfig.orientation == UIInterfaceOrientationLandscapeRight) {
        _videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
    } else {
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    }
    //镜像策略
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    //预览 view
    _gpuImageView = [[GPUImageView alloc] initWithFrame:self.preview.bounds];
    [self.preview addSubview:_gpuImageView];
    if (self.videoConfig.width == 360 && self.videoConfig.height == 640) {
        if (self.videoConfig.orientation == UIInterfaceOrientationPortrait) {
            _cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(((480-360) / 2) / 480, 0, 360.0/480.0, 1.0)];
        } else {
            _cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, ((480-360) / 2) / 480, 1.0, 360.0/480.0)];
        }
        [_videoCamera addTarget:_cropFilter];
    }
//    [_cropFilter addTarget:_gpuImageView];
    
    //美颜滤镜
    _beautifyFilter = [[GPUImageBeautifyFilter alloc] init]; // 60% CPU
    
    if (self.videoConfig.width == 360 && self.videoConfig.height == 640) {
        [_cropFilter addTarget:_beautifyFilter];
    } else {
        [_videoCamera addTarget:_beautifyFilter];
    }
    
    //美颜滤镜
    [_beautifyFilter addTarget:_gpuImageView];
    
    //数据处理
    _dataHandler = [[AWGPUImageAVCaptureDataHandler alloc] initWithImageSize:CGSizeMake(self.videoConfig.width, self.videoConfig.height) resultsInBGRAFormat:YES capture:self];
//    [_cropFilter addTarget:_dataHandler];
    [_beautifyFilter addTarget:_dataHandler];
    _videoCamera.awAudioDelegate = _dataHandler;
    
    [self.videoCamera startCameraCapture];
    
    [self updateFps:self.videoConfig.fps];
}

-(BOOL)startCaptureWithRtmpUrl:(NSString *)rtmpUrl{
    return [super startCaptureWithRtmpUrl:rtmpUrl];
}

-(void)switchCamera{
    [self.videoCamera rotateCamera];
    [self updateFps:self.videoConfig.fps];
}

- (void)switchBeautyFace {

}

-(void)onStartCapture{
}

-(void)onStopCapture{
}

-(void)dealloc{
    [self.videoCamera stopCameraCapture];
}

@end
