//
//  VoiceItem.h
//
//

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
