//
//  LEDReplayKitRecorder.m
//  LEdulineTeacher
//
//  Created by 欧学森 on 2017/11/27.
//  Copyright © 2017年 ouxuesen. All rights reserved.
//

#import "LEDReplayKitRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MCAlertController.h"

@interface LEDReplayKitRecorder()<RPScreenRecorderDelegate,RPPreviewViewControllerDelegate>
@property (strong, nonatomic) RPScreenRecorder *screenRecorder;
@property (strong, nonatomic) AVAssetWriter *assetWriter;

@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *micInput;
@property (nonatomic, strong) AVAssetWriterInput *appInput;

@property (nonatomic, assign) BOOL videoSessionStarted;
@property (nonatomic, assign) BOOL micSessionStarted;
@property (nonatomic, assign) BOOL appSessionStarted;

@property(nonatomic,strong)NSMutableArray* audioArray;
@end
@implementation LEDReplayKitRecorder
//开始录屏
- (void)StartRecoderWithSize:(CGSize)sizeScreen {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (!_audioArray) {
        _audioArray = [NSMutableArray new];
    }
    //设置为播放和录音状态，以便可以在录制完成后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];

    self.screenRecorder = [RPScreenRecorder sharedRecorder];
    if (self.screenRecorder.isRecording) {
        return;
    }
    [self setUpWriterWithSize:sizeScreen];
    if (![self.assetWriter startWriting]) {
        NSLog(@"startWriting error");
        return;
    }
    if (@available(iOS 11.0, *)) {
        {
        [self.screenRecorder setMicrophoneEnabled:YES];
        self.screenRecorder.delegate = self;
        __weak typeof(self) weakSelf = self;
        [self.screenRecorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            if (CMSampleBufferDataIsReady(sampleBuffer)) {
                if (!CMSampleBufferDataIsReady(sampleBuffer)) return;
                
                if (self.assetWriter.status != AVAssetWriterStatusWriting){
                    NSLog(@"self.assetWriter.status != AVAssetWriterStatusWriting");
                  return;
                }
                switch (bufferType) {
                    case RPSampleBufferTypeVideo:
                        if (!weakSelf.videoSessionStarted) {
                            weakSelf.videoSessionStarted = YES;
                            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                        }
                        
                        if (weakSelf.videoInput.isReadyForMoreMediaData) {
                            [weakSelf.videoInput appendSampleBuffer:sampleBuffer];
                        }else{
                             NSLog(@"videoInput is not ready");
                        }
                        break;
                    case RPSampleBufferTypeAudioMic:
//                        if (!weakSelf.micSessionStarted) {
//                            weakSelf.micSessionStarted = YES;
//                            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
//                        }
                        if (!weakSelf.videoSessionStarted) {
                            return;
                        }
                        if (weakSelf.micInput.isReadyForMoreMediaData) {
                            if (![weakSelf.micInput appendSampleBuffer:sampleBuffer]) {
                                NSLog(@"micInput appendSampleBuffer error ");
                            };
                        }else{
                            NSLog(@"micInput is not ready");
                        }
                        break;
                    case RPSampleBufferTypeAudioApp:
//                        if (!weakSelf.appSessionStarted) {
//                            weakSelf.appSessionStarted = YES;
//
////                             I tried to correct the drift that happens with AirPods, didn't work very well
//                                                CMTime baseTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//                                                CMTime correctedTime = CMTimeSubtract(baseTime, CMTimeMakeWithSeconds(0.3, baseTime.timescale));
//
//                                                #ifdef DEBUG
//                                                NSLog(@"baseTime = %.4f", CMTimeGetSeconds(baseTime));
//                                                NSLog(@"correctedTime = %.4f", CMTimeGetSeconds(correctedTime));
//                                                #endif
//
//                            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
//                        }
//
                        if (!weakSelf.videoSessionStarted) {
                            return;
                        }
                        if (weakSelf.appInput.isReadyForMoreMediaData) {
                            if (![weakSelf.appInput appendSampleBuffer:sampleBuffer]) {
                                NSLog(@"appInput appendSampleBuffer error ");
                            };
                        }else{
                            NSLog(@"appInput is not ready");
                        }
                        break;
                    default: break;
                }
            }
            } completionHandler:^(NSError * _Nullable error) {
                if (!error) {
//                    AVAudioSession *session = [AVAudioSession sharedInstance];
//                    [session setActive:YES error:nil];
                    // Start recording
                    NSLog(@"Recording started successfully.");
                }else{
                    //show alert
                    NSLog(@"error = %@",error);
                }
            }];
        }
    } else {
        // Fallback on earlier versions
    }
    
}

-(void)setUpWriterWithSize:(CGSize)sizeScreen
{
    NSError *error = nil;
    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = pathDocuments[0];
    
    NSString *videoOutPath = [[outputURL stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", arc4random() % 1000]] stringByAppendingPathExtension:@"mov"];
    
    
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeQuickTimeMovie error:&error];
    //audio

    NSDictionary <NSString *, id> *appAudioSettings = @{
                                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                                        AVNumberOfChannelsKey: @(1),
                                                        AVSampleRateKey: @(44100.0),
                                                        AVEncoderBitRateKey: @(128000)
                                                        };


    self.appInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:appAudioSettings];
    [self.appInput setExpectsMediaDataInRealTime:YES];
    [self.assetWriter addInput:self.appInput];
   //mic
    NSDictionary <NSString *, id> *micAudioSettings = @{
                                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                                        AVNumberOfChannelsKey: @(2),
                                                        AVSampleRateKey: @(44100.0),
                                                        AVEncoderBitRateKey: @(128000)
                                                        };
    self.micInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:micAudioSettings];
    [self.micInput setExpectsMediaDataInRealTime:YES];
    [self.assetWriter addInput:self.micInput];


    
    NSNumber* width= [NSNumber numberWithFloat:sizeScreen.width];
    NSNumber* height = [NSNumber numberWithFloat:sizeScreen.height];
    NSDictionary *compressionProperties = @{
                                            AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel,
//                                            AVVideoScalingModeKey      : AVVideoScalingModeResizeAspectFill,
                                            AVVideoAverageBitRateKey       : @(sizeScreen.width * sizeScreen.height * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @15,//帧数
                                            AVVideoExpectedSourceFrameRateKey:@15,
                                            };
 
    
    if (@available(iOS 11.0, *)) {
        NSDictionary *videoSettings = @{
                                        AVVideoCodecKey:AVVideoCodecH264,
                                    AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,

                                        AVVideoWidthKey                 : width,
                                        AVVideoHeightKey                : height,
                                        AVVideoCompressionPropertiesKey:compressionProperties
                                        };
        
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    } else {
        // Fallback on earlier versions
    }
    self.videoInput.transform = CGAffineTransformIdentity;
    self.videoInput.transform = [self videoTransformForDeviceOrientation];
//    [self.assetWriterInput setMediaTimeScale:60];
    [self.videoInput setExpectsMediaDataInRealTime:YES];
      [self.assetWriter addInput:self.videoInput];
    
   
    
    if (error) {
        NSLog(@"error = %@",error);
    }
    
}
- (CGAffineTransform)videoTransformForDeviceOrientation
{
    CGAffineTransform videoTransform;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            videoTransform = CGAffineTransformIdentity;
    }
    return videoTransform;
}
- (void)stopDecoderWithBlock:(StopDecoderComplete)complete
{
    if (@available(iOS 11.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"Recording stopped successfully. Cleaning up...");
                    [self.videoInput markAsFinished];
                    [self.appInput markAsFinished];
                     [self.micInput markAsFinished];
                    __weak LEDReplayKitRecorder*weekSelf = self;
                    [self.assetWriter finishWritingWithCompletionHandler:^{
                        NSLog(@"File Url:  %@",self.assetWriter.outputURL);
                        weekSelf.videoInput = nil;
                        weekSelf.micInput = nil;
                         weekSelf.appInput = nil;
                        weekSelf.assetWriter = nil;
                        weekSelf.screenRecorder = nil;
                    }];
                }else{
                     NSLog(@"error = %@",error);
                }
            }];
        });
        
        
    } else {
        // Fallback on earlier versions
        NSLog(@"hello");
    }
}



@end

