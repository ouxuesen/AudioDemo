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
@property(nonatomic,strong)RPPreviewViewController *RPPreview;
@property AVAssetWriterInput *videoInput;

@property AVAssetWriterInput *audioInput;

@property AVAssetWriterInput *micInput;
@property(nonatomic,strong)AVAssetWriter* assetWriter;
@property(nonatomic,strong)NSMutableArray* videoBuffers;
@property(nonatomic,strong)NSMutableArray* audioBuffers;
@property(nonatomic,strong)NSMutableArray* micBuffers;
@end
@implementation LEDReplayKitRecorder
//开始录屏
- (void)StartRecoder
{
    _audioBuffers = [NSMutableArray new];
    _videoBuffers = [NSMutableArray new];
    _micBuffers = [NSMutableArray new];
    //将开启录屏功能的代码放在主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        if ([[RPScreenRecorder sharedRecorder] isAvailable]) { //判断硬件和ios版本是否支持录屏
            NSLog(@"支持ReplayKit录制");
            //这是录屏的类
            RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
            recorder.delegate = self;
            //在此可以设置是否允许麦克风（传YES即是使用麦克风，传NO则不是用麦克风）
            recorder.microphoneEnabled = YES;
            if (@available(iOS 10.0, *)) {
                recorder.cameraEnabled = NO;
            } else {
                // Fallback on earlier versions
            }
            
            if (@available(iOS 11.0, *)) {
                [recorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                    if (CMSampleBufferIsValid(sampleBuffer)){
                        
                        switch (bufferType) {
                                
                            case RPSampleBufferTypeVideo:
                                
                                [_videoBuffers addObject:(__bridge id _Nonnull)(sampleBuffer)];
                                break;
                            case RPSampleBufferTypeAudioApp:
                                
                            {
                                [_audioBuffers addObject:(__bridge id _Nonnull)(sampleBuffer)];
                            }
                                break;
                            case RPSampleBufferTypeAudioMic:
                            {
                                [_micBuffers addObject:(__bridge id _Nonnull)(sampleBuffer)];
                            }
                                break;
                            default:
                                break;
                        }
                    }
                } completionHandler:^(NSError * _Nullable error) {
                    
                }];
            } else {
                // Fallback on earlier versions
            }
            
            
        } else {
            [self showAlert:@"设备不支持录制" andMessage:@"升级ios系统"];
        }
    });
    
}
- (void)stopDecoderWithBlock:(StopDecoderComplete)complete
{
    _stopDecoderComplete = complete;
    if (![[RPScreenRecorder sharedRecorder] isRecording]) {
        _stopDecoderComplete?_stopDecoderComplete(NO):nil;
        return;
    }
    __weak typeof (self)weakSelf = self;
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder]stopCaptureWithHandler:^(NSError * _Nullable error) {
            if (error) {
                
            }else{
                NSString* filePath =          [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"file.mp4"];
                
                [weakSelf startCreatingMovieFile:filePath size: UIScreen.mainScreen.bounds.size];
            }
        }];
    } else {
        // Fallback on earlier versions
    }
}


//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
//{
//    if ([keyPath isEqualToString:@"recording"]) {
//        NSLog(@"keyPath === %@",object);
//        if ([change valueForKey:@"recording"] == 0) {
//            NSLog(@"可以录制");
//        }else
//        {
//            NSLog(@"++++++++++++不可以");
//        }
//    }
//}
//显示弹框提示
- (void)showAlert:(NSString *)title andMessage:(NSString *)message {
    if (!title) {
        title = @"";
    }
    if (!message) {
        message = @"";
    }
    MCAlertView * alertView = [MCAlertView initWithTitle:title message:message cancelButtonTitle:@"cancle"];
    [alertView showWithCompletionBlock:^(NSInteger buttonIndex) {
        
    }];
}
-(void)startCreatingMovieFile:(NSString*)filePath size:(CGSize)size{
    
    if (!_audioBuffers || !_videoBuffers || !_micBuffers) {
        
        return;
        
    }
    
//    _randomNumber = rand();
//
//    _callWritingFailed = NO;
    
    NSError *error = nil;
   NSURL* _filePath = [NSURL fileURLWithPath:filePath];
    
    error = nil;
    
    _assetWriter = [AVAssetWriter assetWriterWithURL:_filePath fileType:AVFileTypeMPEG4 error:&error];
    
    if (error) {
        
        NSLog(@"AVAssetWriter creation failed with error: %@",[error localizedDescription]);
        
    }
    
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           
                                           [NSNumber numberWithDouble:size.width*size.height], AVVideoAverageBitRateKey,
                                           
                                           nil ];
    
    
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   
                                   nil];
    
    
    
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    AudioChannelLayout acl;
    
    bzero( &acl, sizeof(acl));
    
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSDictionary *audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                                         
                                         [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         
                                         [ NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                         
                                         [ NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                                         
                                         [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                         
                                         [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                         
                                         nil ];
    if ([_assetWriter canApplyOutputSettings:audioOutputSettings forMediaType:AVMediaTypeAudio]) {
        
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        
        self.micInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        
    } else {
        
        NSLog(@"Audio settings are not proper. Please check");
        
    }
    [_videoInput setExpectsMediaDataInRealTime:YES];
    
    if (_videoInput && [_assetWriter canAddInput:_videoInput]) {
        
        [_assetWriter addInput:_videoInput];
        
    }
    [_audioInput setExpectsMediaDataInRealTime:NO];
    
    if (_audioInput && [_assetWriter canAddInput:_audioInput]) {
        
        [_assetWriter addInput:_audioInput];
        
    }
    [_micInput setExpectsMediaDataInRealTime:NO];
    
    if (_micInput && [_assetWriter canAddInput:_micInput]) {
        
        [_assetWriter addInput:_micInput];
        
    }
    NSLog(@"Video samples count: %ld", (unsigned long)_videoBuffers.count);
    NSLog(@"Audio samples count: %ld", (unsigned long)_audioBuffers.count);
    NSLog(@"Microphone samples count: %ld", (unsigned long)_micBuffers.count);
 
    
    BOOL success = [_assetWriter startWriting];
    
    if (success) {
        NSLog(@"Assets Writer successfully started for writing.");
        
    } else {
        NSLog(@"Assets Writer has an issue to start writing. Error is: %@", [_assetWriter error]);
        
    }
    
    CMTime presentationStartTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)[_micBuffers objectAtIndex:0]);
    
    [_assetWriter startSessionAtSourceTime:presentationStartTime];
    
    for(NSInteger i = 0; i < _videoBuffers.count; i++) {
        
        while (!_videoInput.readyForMoreMediaData) {
            
            [NSThread sleepForTimeInterval:0.1];
            
        }
        
        CMTime  presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)_videoBuffers[i]);
    
        NSLog(@"VS: presentationTimeStamp %d", presentationTimeStamp);
        [_videoInput appendSampleBuffer:(__bridge CMSampleBufferRef)_videoBuffers[i]];
        
    }
    
    for(NSInteger i = 0; i < _audioBuffers.count; i++) {
        
        while (!_audioInput.readyForMoreMediaData) {
            
            [NSThread sleepForTimeInterval:0.1];
            
        }
        
        [_audioInput appendSampleBuffer:(__bridge CMSampleBufferRef)_audioBuffers[i]];
        
    }
    
    for(NSInteger i = 0; i < _micBuffers.count; i++) {
        
         NSLog(@"Added Microphone sample.");
        if ([_audioInput isReadyForMoreMediaData] && [_audioInput appendSampleBuffer:(__bridge CMSampleBufferRef)_micBuffers[i]]) {
            
            NSLog(@"Appended Microphone sample successfully.");
            
        } else {
            
//            NSLog:(@"Can't append Microphone sample due to writer is not ready. Writer status is %d and error is: %@", [_assetWriter status], [_assetWriter error]);
            
        }
        
    }
    
    _audioBuffers = nil;
    
    _videoBuffers = nil;
    
    _micBuffers = nil;
    
    [_videoInput markAsFinished];
    
    [_audioInput markAsFinished];
    
    [_micInput markAsFinished];
    
    [_assetWriter finishWritingWithCompletionHandler:^{
        
        NSLog(@"finishWritingWithCompletionHandler");
        
        _assetWriter = nil;
        
        _videoInput = nil;
        
        _audioInput = nil;
        
        _micInput = nil;
        
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];

        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:_filePath completionBlock:^(NSURL *assetURL, NSError *error){

            if(error) {
                NSLog(@"error while saving to camera roll %@",[error localizedDescription]);

            } else {
//                NSError *removeError = nil;
//
//                [[NSFileManager defaultManager] removeItemAtURL:_filePath error:&removeError];
//
//                NSLog(@"%@",[removeError localizedDescription]);

            }

        }];

//        [self dismissViewControllerAnimated:true completion:^{}];
        
    }];
    
}
@end

