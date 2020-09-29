//
//  MeVideoEncoder.m
//  Live
//
//  Created by 王景伟 on 2020/9/29.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "MeVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>
#define NOW (CACurrentMediaTime()*1000)

@interface MeVideoEncoder () {
    VTCompressionSessionRef compressionSession;
    int frameIndex;
    int fps;
    int width;
    int height;
    int bitRate;
    int bitRateLimit;
    
    NSData *headerData;
    
    NSFileHandle *fileHandle;
    NSMutableData *_data;
    NSString *h264File;
    
    bool spsppsisWrite;
    
    NSData *sps;
    NSData *pps;
}

@end

@implementation MeVideoEncoder

- (instancetype)init {
    if (self = [super init]) {
        [self initData];
        [self prepareToEncode];
    }
    return self;
}

- (void)initData {
    /// 第几帧
    frameIndex = 0;
    width = 480;
    height = 640;
    /// 帧率
    fps = 30;
    /// 码率
    bitRate = width * height * 3 * 4 * 8;
    bitRateLimit = width * height * 3 * 4;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof(bytes) - 1);
    headerData = [NSData dataWithBytes:bytes length:length];
    
    h264File = [documentsDirectory stringByAppendingPathComponent:@"test.h264"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
}

- (void)prepareToEncode {
    VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, compressionOutputCallback, (__bridge void *)(self), &compressionSession);
    
    /// 2.设置实时编码输出
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    /// 3.设置期望的帧率
    CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    /// 4.设置码率，上限，单位是bps(比特率) 如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    
    /// 5.设置码率，均值，单位是byte
    CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);

    /// 6.设置关键帧间隔（GOPsize)
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps * 2));
    
    /// 7.准备编码
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
}

/// 输出编码后的数据
void compressionOutputCallback(void *outputCallbackRefCon,void *sourceFrameRefCon,OSStatus status,VTEncodeInfoFlags infoFlags,CM_NULLABLE CMSampleBufferRef sampleBuffer) {
    
    /// 1.有错误返回
    if (status != noErr) return;
    if (!CMSampleBufferDataIsReady(sampleBuffer)) return;
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) return;
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) return;
    
    /// 3.获取时间戳
    //uint64_t timeStamp = [((__bridge_transfer NSNumber *)sourceFrameRefCon) longLongValue];
    
    /// 4.获取对象
    MeVideoEncoder *encoder = (__bridge MeVideoEncoder *)(outputCallbackRefCon);
    
    /// 5.判断是否为关键帧
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachments, 0);
    bool keyFrame = CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    
    /// 获取sps和pps写入头部
    if (keyFrame && !encoder->spsppsisWrite) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        /// sps
        size_t spsSize,spsCount; const uint8_t *spsData;
        OSStatus spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsData, &spsCount, &spsSize, 0);
        
        /// pps
        size_t ppsSize,ppsCount; const uint8_t *ppsData;
        OSStatus ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsData, &ppsCount, &ppsSize, 0);
        
        if (spsStatus == noErr && ppsStatus == noErr) {
            encoder->spsppsisWrite = true;
            NSData *sps = [NSData dataWithBytes:spsData length:spsSize];
            NSData *pps = [NSData dataWithBytes:ppsData length:ppsSize];
            [encoder writeDataWithHeaderSps:sps pps:pps];
        }
    }
    
    
    size_t lengthAtOffset,totalLength;
    char *dataPointer;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus dataStatus = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &dataPointer);
    if (dataStatus == noErr) {
        size_t bufferOffset = 0;
        /// 1.返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            
            /// 2.获取nalu的长度
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            /// 3.大端模式转化为系统端模式
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder writeDataWithFrameData:data];
            
            
            LFVideoFrame *frame = LFVideoFrame.new;
            frame.timestamp = NOW;
            frame.pps = encoder->pps;
            frame.sps = encoder->sps;
            frame.isKeyFrame = keyFrame;
            frame.data = data;
            if (encoder.delegate && [encoder.delegate respondsToSelector:@selector(videoEncodeCallBack:)]) {
                [encoder.delegate videoEncodeCallBack:frame];
            }
            
            /// 3. 读取下一个nalu，一次回调可能包含多个nalu
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
    
}

/** 编码 需要对每一帧进行编码 */
- (void)encodeVideoSamepleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageRef = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /// 2.根据当前的帧数,创建CMTime的时间
    CMTime time = CMTimeMake(frameIndex++, 1000);
    
    VTEncodeInfoFlags flags;
    
    /// 3.开始编码
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, imageRef, time, kCMTimeInvalid, NULL, (__bridge void *)(self), &flags);
    
    if (status != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame error");
    }
}

/// 头部写入 sps和pps
- (void)writeDataWithHeaderSps:(NSData*)sps pps:(NSData*)pps {
    [fileHandle writeData:headerData];
    [fileHandle writeData:sps];
    [fileHandle writeData:headerData];
    [fileHandle writeData:pps];
    self->sps = sps;
    self->pps = pps;
}

/// 写入每一帧的H264数据
- (void)writeDataWithFrameData:(NSData*)data {
    if (fileHandle != NULL) {
        [fileHandle writeData:headerData];
        [fileHandle writeData:data];
    }
}

- (void)stopEncode {
    VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(compressionSession);
    CFRelease(compressionSession);
    compressionSession = NULL;
    
    [fileHandle closeFile];
    fileHandle = NULL;
}
@end
