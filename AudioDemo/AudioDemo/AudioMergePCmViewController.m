//
//  AudioMergePCmViewController.m
//  AudioDemo
//
//  Created by 欧学森 on 08/12/2017.
//  Copyright © 2017 ouxuesen. All rights reserved.
//

#import "AudioMergePCmViewController.h"
#import "LYPlayer.h"
#import <UIKit/UIKit.h>
#import "ExtAudioFileMixer.h"
#import "LEDReplayKitRecorder.h"

@interface AudioMergePCmViewController ()
@property(nonatomic,strong)LYPlayer* player;
@property(nonatomic,strong)LEDReplayKitRecorder* kitRecorder;
- (IBAction)playBUttonCclick:(UIButton *)sender;
@end

@implementation AudioMergePCmViewController
-(LYPlayer *)player
{
    if (!_player) {
        _player = [[LYPlayer alloc]init];
    }
    return _player;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSURL*)getAbcFullPath
{
    return [[NSBundle mainBundle] URLForResource:@"audio" withExtension:@"wav"];
}
-(NSURL*)getTestFullPath
{
    return [[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"mp3"];
}
-(NSURL*)getMovieFullPath
{
    return[[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"mp4"];
}
-(NSURL*)getWavComFullPath
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/audio.wav"];
    return [NSURL fileURLWithPath:path];
}
-(NSURL*)getComFullPath
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/record.mp4"];
    return [NSURL fileURLWithPath:path];
}
- (IBAction)playBUttonCclick:(UIButton *)sender {
    NSLog(@"NSURL = %@",[self getComFullPath]);
    if (sender.tag == 0) {
        [self.player playWithURl:[self getAbcFullPath]];
    }else if (sender.tag == 1){
        [self.player stop];
        
         [self.player playWithURl:[self getTestFullPath]];
    }else if (sender.tag == 2){
//        [ExtAudioFileMixer sourceURLs:@[[self getAbcFullPath],[self getTestFullPath]] videoUrl:[self getMovieFullPath] composeToURL:[self getComFullPath] completed:^(NSError *error) {
//
//        }];
//       ExtAudioFileMixer*audioMix = [[ExtAudioFileMixer alloc] init];
//        [audioMix convertPcm2Wav:[[self getAbcFullPath] path] dst_file:[[self getWavComFullPath] path] channels:1 sample_rate:44100];
        if (!_kitRecorder) {
            _kitRecorder = [LEDReplayKitRecorder alloc];
        }
          [_kitRecorder StartRecoder];
    }else if (sender.tag == 3){
//         [self.player playWithURl:[self getComFullPath]];
        [_kitRecorder stopDecoderWithBlock:^(BOOL success) {
            
        }];
    }
    
}



@end
