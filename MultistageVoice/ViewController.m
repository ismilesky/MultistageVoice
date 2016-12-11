//
//  ViewController.m
//  MultistageVoice
//
//  Copyright © 2016年 Felix. All rights reserved.
//

#import "ViewController.h"
#import "AVManager.h"
#import "VoiceItem.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"combine.mp4" ofType:nil];
    /**
     AVAsset的属性从根本上来说是多媒体文件(如视频文件)的属性, 可以好好看一下AVAVFoundation, 关于音视频处理的
     */
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"4355CCF0-1B93-443C-9FA7-91CCD0CFE05B.mov" ofType:nil];
    VoiceItem *voiceItem1 = [[VoiceItem alloc] init];
    voiceItem1.filePath = path1;
    // 目的是为了将这段音频插入到视频的开始
// ---------------------------------------------------------------
    typedef struct
    {
        CMTimeValue	value;		/*! @field value The value of the CMTime. value/timescale = seconds. */
        CMTimeScale	timescale;	/*! @field timescale The timescale of the CMTime. value/timescale = seconds.  */
        CMTimeFlags	flags;		/*! @field flags The flags, eg. kCMTimeFlags_Valid, kCMTimeFlags_PositiveInfinity, etc. */
        CMTimeEpoch	epoch;		/*! @field epoch Differentiates between equal timestamps that are actually different because
                                 of looping, multi-item sequencing, etc.
                                 Will be used during comparison: greater epochs happen after lesser ones.
                                 Additions/subtraction is only possible within a single epoch,
                                 however, since epoch length may be unknown/variable. */
    } CMTime;
    /**
     若要获取所需时间（秒为单位） value/timescale = seconds
     */
    
// ----------------------------------------------------------------
    voiceItem1.startTime = CMTimeMake(0, asset.duration.timescale);
    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"5B310DBA-F295-47DE-9D32-0F831776D219.mov" ofType:nil];
    VoiceItem *voiceItem2 = [[VoiceItem alloc] init];
    voiceItem2.filePath = path2;
    // 目的是为了将这段音频插入到视频的8秒处
    voiceItem2.startTime = CMTimeMake(8*asset.duration.timescale, asset.duration.timescale);
    
    NSArray *items = [NSArray arrayWithObjects:voiceItem1,voiceItem2, nil];
    
    NSString *path = @"/Users/kongfei/Desktop/max.mp4"; // 要导出视频的路径,以桌面为例
    [[AVManager sharedInstance] combineVideo:videoPath withAudios:items outPutVideoPath:path completedBlock:^(BOOL success, NSString *errorMsg) {
        if (success) {
            NSLog(@"Success");
        } else {
            NSLog(@"--->> %@", errorMsg);
        }
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
