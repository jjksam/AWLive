
Modification base on the code. Will be able to push stream to some rtmp push address with either Portrait or Landscape oriention.

TODO: integrate with Android SDK so the SDK will be available to Android & iOS platform.
功能范围
---
- 视频捕获：系统方法捕获，GPUImage捕获，CMSampleRef解析
- 美颜滤镜：GPUImage，
- 视频变换：libyuv
- 横屏直播
- 软编码：faac，x264
- 硬编码：VideoToolbox(aac/h264)
- libaw：C语言函数库
- flv协议及编码
- 推流协议：librtmp，rtmp重连，rtmp各种状态回调

代码使用及注意
---

注1：项目中所有相关的文件名，类名，全局变量，全局方法都会加AW/aw作为前缀。
注2：项目中关键代码都使用c语言编写，理论上可以很容易地移植到android中。
