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

@interface MeRecordController ()

@end

@implementation MeRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    /// 1.GPUImage 获取到    LFVideoCapture
    
    
    /// 2.进行 H264编码     LFHardwareVideoEncoder
    
    
    /// 3.打包flv格式 经过RTMP上传到推流服务器  pili-librtmp：因为rtmp协议所传输的视频流，就要求是flv格式
    
}


@end
