//
//  MeAudioEncoder.h
//  Live
//
//  Created by 王景伟 on 2020/9/28.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SQAudioConfig  : NSObject
@property(nonatomic,assign)NSInteger bitrate;
@property(nonatomic,assign)NSInteger channelCount;
/**采样率*/
@property (nonatomic, assign) NSInteger sampleRate;//(默认44100)
/**采样点量化*/
@property (nonatomic, assign) NSInteger sampleSize;//(16)

@end

@protocol SQAudioEncoderDelegate<NSObject>
-(void)audioEncodeCallBack:(NSData *)aacData;
@end

@interface MeAudioEncoder : NSObject
/**编码器配置*/
@property (nonatomic, strong) SQAudioConfig *config;
@property (nonatomic, weak) id<SQAudioEncoderDelegate> delegate;

/**初始化传入编码器配置*/
- (instancetype)initWithConfig:(SQAudioConfig*)config;

/**编码*/
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
