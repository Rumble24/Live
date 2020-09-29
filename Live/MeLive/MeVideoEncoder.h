//
//  MeVideoEncoder.h
//  Live
//
//  Created by 王景伟 on 2020/9/29.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LFVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN




@protocol MeVideoEncoderDelegate<NSObject>
@optional
- (void)videoEncodeCallBack:(LFVideoFrame *)frame;
@end


@interface MeVideoEncoder : NSObject

@property (nonatomic, weak) id<MeVideoEncoderDelegate> delegate;

/** YUV编码H264 */
- (void)encodeVideoSamepleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)stopEncode;
@end

NS_ASSUME_NONNULL_END
