//
//  ViewController.m
//  AudioDemo
//
//  Created by 欧学森 on 08/12/2017.
//  Copyright © 2017 ouxuesen. All rights reserved.
//

#import "ViewController.h"
#import "AudioMergePCmViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord  error:nil];
    AudioMergePCmViewController * viewC= [[AudioMergePCmViewController alloc]initWithNibName:@"AudioMergePCmViewController" bundle:nil];
    [self addChildViewController:viewC];
    [self.view addSubview:viewC.view];
    viewC.view.bounds =self.view.bounds;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
