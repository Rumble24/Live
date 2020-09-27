//
//  ViewController.m
//  Live
//
//  Created by 王景伟 on 2020/9/25.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "ViewController.h"
#import <LFLiveKit.h>
#import <AVKit/AVKit.h>


// 屏幕尺寸
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

#define rtmpUrl @"rtmp://10.10.30.235:1935/rtmplive/roomlyj"
#define localVideoPath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/demo.mp4"]

@interface ViewController ()<LFLiveSessionDelegate>

@property (nonatomic, strong) LFLiveSession *session;

@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic, strong) UIView *preView;//视频图层

///< 开始/结束
@property (nonatomic, strong) UIButton *startButton;
///< 播放
@property (nonatomic, strong) UIButton *playBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"直播";
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.playBtn];
    [self.view addSubview:self.startButton];
    
    [ViewController getSystemCameraStatus:nil];
    [ViewController getSystemAudioStatus:nil];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDelete = [fileManager removeItemAtPath:localVideoPath error:nil];
    if (isDelete) {
        NSLog(@"删除成功");
    } else {
        NSLog(@"删除失败");
    }
}

+ (void)getSystemCameraStatus:(PermissionBlock)response {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted|| authStatus == AVAuthorizationStatusDenied) {
        if (response) response(NO);
    } else if(authStatus == AVAuthorizationStatusNotDetermined || authStatus == AVAuthorizationStatusAuthorized){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response) response(granted);
            });
        }];
    } else {
        if (response) response(YES);
    }
}

+ (void)getSystemAudioStatus:(PermissionBlock)response {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (response) response(granted);
        });
    }];
}

//开始直播
- (void)startLive {
    LFLiveStreamInfo *streamInfo = [LFLiveStreamInfo new];
    streamInfo.url = rtmpUrl;
    [self.session startLive:streamInfo];
}

//结束直播
- (void)stopLive {
    [self.session stopLive];
    
    //播放本地视频
    dispatch_async(dispatch_get_main_queue(), ^{
        AVPlayerViewController* vc = [[AVPlayerViewController alloc] init];
        vc.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:localVideoPath]];
        [self presentViewController:vc animated:YES completion:nil];
    });
}

/** 直播相关的事件 */
- (void)startLive:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        [self startLive];
    } else {
        [self stopLive];
    }
}
/** 开始播放视频 */
- (void)startPlayAction:(UIButton *)sender {
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:localVideoPath]];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
    [self.view.layer addSublayer:playerLayer];
    [player play];
}


#pragma mark -------------- LFLiveSessionDelegate --------------
//推流状态改变
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange: (LFLiveState)state{
    
    NSString* stateStr;
    switch (state) {
        case LFLiveReady:
            stateStr = @"准备";
            break;
            
        case LFLivePending:
            stateStr = @"连接中";
            break;
            
        case LFLiveStart:
            stateStr = @"已连接";
            break;
            
        case LFLiveStop:
            stateStr = @"已断开";
            break;
            
        case LFLiveError:
            stateStr = @"连接出错";
            break;
            
        case LFLiveRefresh:
            stateStr = @"正在刷新";
            break;
            
        default:
            break;
    }
    
    NSLog(@"推流状态改变  %@",stateStr);
}

//推流信息
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug*)debugInfo {
    NSLog(@"推流信息  %@",session.currentImage);
}

//推流错误信息
- (void)liveSession:(nullable LFLiveSession*)session errorCode:(LFLiveSocketErrorCode)errorCode{
    switch (errorCode) {
        case LFLiveSocketError_PreView:
             NSLog(@"预览失败");
            break;
        case LFLiveSocketError_GetStreamInfo:
            NSLog(@"获取流媒体信息失败");
            break;
        case LFLiveSocketError_ConnectSocket:
            NSLog(@"连接socket失败");
            break;
        case LFLiveSocketError_Verification:
            NSLog(@"验证服务器失败");
            break;
        case LFLiveSocketError_ReConnectTimeOut:
            NSLog(@"重新连接服务器超时");
            break;
        default:
            break;
    }
}
- (LFLiveSession *)session {
    if (!_session) {
        //默认音视频配置
        //初始化session要传入音频配置和视频配置
        //音频的默认配置为:采样率44.1 双声道
        //视频默认分辨率为360 * 640
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:[LFLiveVideoConfiguration defaultConfiguration]];
        _session.reconnectCount = 5;//重连次数
        _session.saveLocalVideo = YES;
        _session.saveLocalVideoPath = [NSURL fileURLWithPath:localVideoPath];
        _session.delegate = self;
        _session.running = YES;
        /// 显示试图
        self.preView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth)];
        self.preView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.preView];
        _session.preView = self.preView;
        
    }
    return _session;
}
///< 开始/结束
- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_startButton setTitle:@"开始" forState:0];
        [_startButton setTitle:@"结束" forState:UIControlStateSelected];
        _startButton.frame = CGRectMake(0, 88 + 20, kScreenWidth/4.0, 50);
        [_startButton addTarget:self action:@selector(startLive:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startButton;
}
///< 播放
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_playBtn setTitle:@"播放" forState:0];
        _playBtn.frame = CGRectMake(kScreenWidth/4.0, 88 + 20, kScreenWidth/4.0, 50);
        [_playBtn setTitleColor:[UIColor redColor] forState:0];
        [_playBtn addTarget:self action:@selector(startPlayAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}
@end
