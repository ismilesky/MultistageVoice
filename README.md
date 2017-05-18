## MultistageVoice
   多段音频合成
## Usage
- 安装

  下载文件，将`VoiceItem.h` `VoiceItem.m` `AVManager.h` `AVManager.m` 拖到工程里面

- 使用

`VoiceItem` 模型类

``` 
//  VoiceItem.h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
  关于音频设置的Model类，需要的属性可自行添加
 */

@interface VoiceItem : NSObject

/**
 路径
 */
@property (strong, nonatomic) NSString *filePath;

/**
 音频的插入起始时间
 */
@property (assign, nonatomic) CMTime startTime;
@end

```

`AVManager`工具类

```
//  AVManager.h

#import <Foundation/Foundation.h>

@class VoiceItem;

typedef void(^CompFinalCompletedBlock)(BOOL success, NSString *errorMsg);

@interface AVManager : NSObject

+ (instancetype)sharedInstance;

/**
 多段音频合成

 @param videoPath 视频的路径
 @param voices VoiceItem的数组(多段音频)
 @param outputVideoPath 导出路径
 @param completedBlock 完成回调
 */
- (void)combineVideo:(NSString *)videoPath
       withAudios:(NSArray<VoiceItem *> *)voices
     outPutVideoPath:(NSString *)outputVideoPath
      completedBlock:(CompFinalCompletedBlock)completedBlock;


/**
 多段音频混音 （例如： 录音 和 音乐 混音）

 @param voices VoiceItem的数组(多段音频)
 @param musics VoiceItem的数组(多段音频)
 @param outPutPath 输出路径 （.m4a格式）
 @param completedBlock 完成回调
 */
- (void)audioMixWithVoices:(NSArray<VoiceItem *> *)voices
                 musics:(NSArray<VoiceItem *> *)musics
                    outPutPath:(NSString *)outPutPath
                completedBlock:(CompFinalCompletedBlock)completedBlock;
@end

```
Example:

```
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"combine.mp4" ofType:nil];
    
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"4355CCF0-1B93-443C-9FA7-91CCD0CFE05B.mov" ofType:nil];
    VoiceItem *voiceItem1 = [[VoiceItem alloc] init];
    voiceItem1.filePath = path1;
    voiceItem1.startTime = CMTimeMake(0, asset.duration.timescale);
    
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"5B310DBA-F295-47DE-9D32-0F831776D219.mov" ofType:nil];
    VoiceItem *voiceItem2 = [[VoiceItem alloc] init];
    voiceItem2.filePath = path2;
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
    
```


--------------
可能不是很完美，不足之处请提出来！
