//
//  MeAudioEncoder.h
//  Live
//
//  Created by 王景伟 on 2020/9/28.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LFAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MeAudioEncoderDelegate<NSObject>

- (void)audioEncodeCallBack:(LFAudioFrame *)frame;

@end

@interface MeAudioEncoder : NSObject

@property (nonatomic, weak) id<MeAudioEncoderDelegate> delegate;

/**编码*/
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer;

- (void)stopEncode;
@end

NS_ASSUME_NONNULL_END
