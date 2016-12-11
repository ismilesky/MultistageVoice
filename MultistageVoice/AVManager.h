//
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
