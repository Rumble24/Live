//
//  MeRecordController.m
//  Live
//
//  Created by 王景伟 on 2020/9/27.
//  Copyright © 2020 王景伟. All rights reserved.
//  GPUImage 获取到    GPUImageFramebuffer.framebufferForOutput<CVPixelBufferRef>;
//  进行 H264编码[sps pps]。 打包CLV格式 经过RTMP上传到推流服务器就可以了
/*
 所以，程序从相机和麦克风捕获到音视频数据后，分别转成 aac和h264格式的音视频帧。

 然后将aac和h264音视频帧合成flv格式的视频后发送到rtmp服务器。客户端就可以播放我们推的流了。
 */


#import "MeRecordController.h"
#import "LFLiveKit.h"
#import "GPUImage.h"
#import <AVKit/AVKit.h>
#import <VideoToolbox/VideoToolbox.h>
#import "MeAudioEncoder.h"
#import "LFHardwareVideoEncoder.h"
#import "LFStreamRTMPSocket.h"

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height
#define NOW (CACurrentMediaTime()*1000)
#define rtmpUrl @"rtmp://10.10.30.235:1935/rtmplive/roomlyj"

@interface MeRecordController () <GPUImageVideoCameraDelegate, SQAudioEncoderDelegate, LFVideoEncodingDelegate, LFStreamSocketDelegate>
///< 开始/结束
@property (nonatomic, strong) UIButton *startButton;
///< 播放
@property (nonatomic, strong) UIButton *playBtn;
///< 视频摄像头
@property (nonatomic, strong) GPUImageVideoCamera *camera;
///< 视频的显示player
@property (nonatomic, strong) GPUImageView *previewLayer;
///< 写入本地
@property (nonatomic, strong) GPUImageMovieWriter *writer;

@property (nonatomic, strong) NSString *localPath;

@property (nonatomic, strong) MeAudioEncoder *encoder;
/// 视频编码
@property (nonatomic, strong) id<LFVideoEncoding> videoEncoder;
/// 上传
@property (nonatomic, strong) id<LFStreamSocket> socket;
@end

@implementation MeRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self setUpView];
    
    [self createGPUImageVideoCamera];
}

- (void)setUpView {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.playBtn];
    [self.view addSubview:self.startButton];
}


#pragma mark - 1.GPUImage 获取到    LFVideoCapture
- (void)createGPUImageVideoCamera {
    self.localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"record.mp4"];
    /// 判断路径是否存在 存在那么删除
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.localPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.localPath error:nil];
    }
    self.camera = [[GPUImageVideoCamera alloc]initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    /// 设置屏幕的方向
    self.camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.camera.delegate = self;
    
    /// 显示层
    self.previewLayer = [[GPUImageView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth)];
    self.previewLayer.fillMode = kGPUImageFillModePreserveAspectRatio;
    [self.view addSubview:self.previewLayer];
    [self.camera addTarget:self.previewLayer];
    
    /// size 必须要和上面的分辨率成百分比
    self.writer = [[GPUImageMovieWriter alloc]initWithMovieURL:[NSURL fileURLWithPath:self.localPath] size:CGSizeMake(kScreenWidth, kScreenWidth * 640 / 480.f)];
    self.writer.encodingLiveVideo = YES;
    /// 音频
    self.camera.audioEncodingTarget = self.writer;
    [self.camera addTarget:self.writer];
    
    self.encoder = [[MeAudioEncoder alloc]initWithConfig:[[SQAudioConfig alloc]init]];
    self.encoder.delegate = self;
    
    self.videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:[LFLiveVideoConfiguration defaultConfiguration]];
    [self.videoEncoder setDelegate:self];
    
    LFLiveStreamInfo *streanInfo = LFLiveStreamInfo.new;
    streanInfo.url = rtmpUrl;
    _socket = [[LFStreamRTMPSocket alloc] initWithStream:streanInfo reconnectInterval:1 reconnectCount:5];
    [_socket setDelegate:self];
}

#pragma mark - 2.视频进行 H264编码     LFHardwareVideoEncoder
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelbuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.videoEncoder encodeVideoData:pixelbuffer timeStamp:NOW];
}

- (void)videoEncoder:(nullable id<LFVideoEncoding>)encoder videoFrame:(nullable LFVideoFrame *)frame {
    [self.socket sendFrame:frame];
}

#pragma mark - 3.音频进行 AAC编码     LFHardwareVideoEncoder
- (void)willOutputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.encoder encodeAudioSamepleBuffer:sampleBuffer];
}

- (void)audioEncodeCallBack:(NSData *)aacData {
    LFAudioFrame *audioFrame = [LFAudioFrame new];
    audioFrame.timestamp = NOW;
    audioFrame.data = aacData;
    [self.socket sendFrame:audioFrame];
}






#pragma mark - 4.打包flv格式 经过RTMP上传到推流服务器  pili-librtmp：因为rtmp协议所传输的视频流，就要求是flv格式


/// 开始按钮点击
- (void)startButtonClick:(UIButton *)btn {
    btn.selected = !btn.isSelected;
    if (btn.isSelected) {
        [self startLive];
    } else {
        [self stopLive];
    }
}

/// 开始直播
- (void)startLive {
    [self.camera startCameraCapture];
    [self.writer startRecording];
    [self.socket start];
}

/// 结束直播
- (void)stopLive {
    [self.writer finishRecording];
    [self.camera stopCameraCapture];
    [self.socket stop];
}

/// 播放本地视频
- (void)startPlayRecorded:(UIButton *)btn {
    AVPlayerViewController* vc = [[AVPlayerViewController alloc] init];
    vc.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:self.localPath]];
    [self presentViewController:vc animated:YES completion:nil];
}

///< 开始/结束
- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_startButton setTitle:@"开始" forState:0];
        [_startButton setTitle:@"结束" forState:UIControlStateSelected];
        _startButton.frame = CGRectMake(0, kScreenHeight - 88 - 50, kScreenWidth/2.0, 50);
        [_startButton addTarget:self action:@selector(startButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startButton;
}
///< 播放
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_playBtn setTitle:@"播放" forState:0];
        _playBtn.frame = CGRectMake(kScreenWidth/2.0, kScreenHeight - 88 - 50, kScreenWidth/2.0, 50);
        [_playBtn setTitleColor:[UIColor redColor] forState:0];
        [_playBtn addTarget:self action:@selector(startPlayRecorded:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}
@end
