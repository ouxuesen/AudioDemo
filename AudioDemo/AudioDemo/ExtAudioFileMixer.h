//
//  ExtAudioFileMixer.h
//  AudioDemo
//
//  Created by 欧学森 on 08/12/2017.
//  Copyright © 2017 ouxuesen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExtAudioFileMixer : NSObject
+ (OSStatus)mixAudio:(NSString *)audioPath1
            andAudio:(NSString *)audioPath2
              toFile:(NSString *)outputPath
  preferedSampleRate:(float)sampleRate;

/// 合并音频文件
/// @param sourceURLs 需要合并的多个音频文件
/// @param toURL      合并后音频文件的存放地址
/// 注意:导出的文件是:m4a格式的.
+ (void) sourceURLs:(NSArray *) sourceURLs videoUrl:(NSURL*)videoUrl composeToURL:(NSURL *) toURL completed:(void (^)(NSError *error)) completed;

-(BOOL)convertPcm2Wav:(NSString*)src_file dst_file:(NSString*)dst_file channels:(int)channels sample_rate:(int)sample_rate;


@end
