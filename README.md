# MultistageVoice
多段音频合成
----------------
- 安装

  下载文件，将`VoiceItem.h` `VoiceItem.m` `AVManager.h` `AVManager.m` 拖到工程里面

- 使用
####模型类
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
####工具类
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

--------------
可能不是很完美，不足之处请提出来！
