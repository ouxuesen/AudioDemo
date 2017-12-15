//
//  LEDReplayKitRecorder.h
//  LEdulineTeacher
//
//  Created by 欧学森 on 2017/11/27.
//  Copyright © 2017年 ouxuesen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>


typedef void(^StopDecoderComplete)(BOOL success);
@protocol LEDReplayKitRecorderDelegate <NSObject>
@optional
- (void)showVideoPreviewController:(RPPreviewViewController *)previewController withAnimation:(BOOL)animation ;
- (void)hideVideoPreviewController:(RPPreviewViewController *)previewController withAnimation:(BOOL)animation;
@end
@interface LEDReplayKitRecorder : NSObject
@property(nonatomic,weak)id<LEDReplayKitRecorderDelegate> delegate;
@property(nonatomic,copy)StopDecoderComplete stopDecoderComplete;
//开始录屏
- (void)StartRecoder;
- (void)stopDecoderWithBlock:(StopDecoderComplete)complete;
@end
