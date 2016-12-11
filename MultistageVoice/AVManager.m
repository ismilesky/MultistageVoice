//
//  AVManager.m
//

#import "AVManager.h"
#import "VoiceItem.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

static AVManager *instance = nil;
@interface AVManager ()
@property (nonatomic, copy) CompFinalCompletedBlock compVideoCompletedBlock;

@property (nonatomic, copy) NSMutableArray<AVMutableAudioMixInputParameters *> *audioMixParams;
@end

@implementation AVManager

+ (instancetype)sharedInstance {
    if (!instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [AVManager new];
        });
    }
    return instance;
}

- (instancetype)copyWithZone:(struct _NSZone *)zone {
    return [AVManager sharedInstance];
}

- (void)combineVideo:(NSString *)videoPath
        withAudios:(NSArray<VoiceItem *> *)voices
        outPutVideoPath:(NSString *)outputVideoPath
        completedBlock:(CompFinalCompletedBlock)completedBlock {
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetVoiceTrack = nil;
    
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *assetVideo = nil;
    if (videoPath) {
        assetVideo = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath] options:optDict];
        NSArray<AVAssetTrack *> *videoTracks = [assetVideo tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] != 0) {
            assetVideoTrack = videoTracks.firstObject;
        }
    }
    
    VoiceItem *voiceItem = voices.firstObject;
    NSString *voicePath = voiceItem.filePath;
    AVURLAsset *assetAudio  = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:voicePath] options:optDict];
    NSArray<AVAssetTrack *> *audioTracks = [assetAudio tracksWithMediaType:AVMediaTypeAudio];
    if ([audioTracks count] != 0) {
        assetVoiceTrack = audioTracks.firstObject;
    }
    
    AVMutableComposition *videoComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [videoComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error;
    if (assetVideoTrack == nil) {
        completedBlock(NO, @"合成视频失败");
        return;
    }
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetVideo.duration) ofTrack:assetVideoTrack atTime:voiceItem.startTime error:&error];
    if (error) {
        completedBlock(NO, @"合成视频失败");
        return;
    }
    
    __block AVMutableCompositionTrack *audioTrack = [videoComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    if (assetVoiceTrack != nil) {
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetAudio.duration) ofTrack:assetVoiceTrack atTime:kCMTimeZero error:&error];
        if (error) {
            completedBlock(NO, @"添加音频失败");
            return;
        }
    }
    
    [voices enumerateObjectsUsingBlock:^(VoiceItem *voiceItem, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            return;
        }
        NSString *audioPath = voiceItem.filePath;
        AVURLAsset *currentAudio = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioPath] options:optDict];
        NSArray *tracks = [currentAudio tracksWithMediaType:AVMediaTypeAudio];
        if (tracks <= 0) {
            *stop = YES;
            completedBlock(NO, @"合成失败");
            return;
        }
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAudio.duration) ofTrack:tracks.firstObject atTime:voiceItem.startTime error:nil];
    }];
    
   
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputVideoPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputVideoPath error:nil];
    }
    AVAssetExportSession *exportor = [[AVAssetExportSession alloc] initWithAsset:videoComposition presetName:AVAssetExportPresetHighestQuality];
    exportor.outputFileType = AVFileTypeMPEG4;
    exportor.outputURL = [NSURL fileURLWithPath:outputVideoPath];
    exportor.shouldOptimizeForNetworkUse = YES;
    [exportor exportAsynchronouslyWithCompletionHandler:^{
        BOOL isSuccess = NO;
        NSString *msg = @"合成完成";
        switch (exportor.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"HandlerVideo -> combinationVidesError: %@", exportor.error.localizedDescription);
                msg = @"合成失败";
                break;
            case AVAssetExportSessionStatusUnknown:
            case AVAssetExportSessionStatusCancelled:
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
                isSuccess = YES;
                break;
        }
        if (completedBlock) {
            completedBlock(isSuccess, msg);
        }
    }];
}

- (void)audioMixWithVoices:(NSArray<VoiceItem *> *)voices
                    musics:(NSArray<VoiceItem *> *)musics
                outPutPath:(NSString *)outPutPath
            completedBlock:(CompFinalCompletedBlock)completedBlock {
    AVMutableComposition *audioComposition = [AVMutableComposition composition];
    [self setUpAndAddAudioAtPath:voices toComposition:audioComposition];
    [self setUpAndAddAudioAtPath:musics toComposition:audioComposition];
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:self.audioMixParams];
    
    [AVAssetExportSession exportPresetsCompatibleWithAsset:audioComposition];
    AVAssetExportSession *export = [[AVAssetExportSession alloc] initWithAsset:audioComposition presetName:AVAssetExportPresetAppleM4A];
    export.audioMix = audioMix;
    export.outputFileType = AVFileTypeAppleM4A;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    NSURL *exportUrl = [NSURL fileURLWithPath:outPutPath];
    export.outputURL = exportUrl;
    [export exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = export.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:{
                NSError *exportError = export.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                if (completedBlock) {
                    completedBlock(NO, exportError.localizedDescription);
                }
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog (@"AVAssetExportSessionStatusCompleted");
                if (completedBlock) {
                    completedBlock(YES, @"混音完成");
                }
            } break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
    }];
}

- (void)setUpAndAddAudioAtPath:(NSArray<VoiceItem *> *)voices toComposition:(AVMutableComposition *)composition {
    VoiceItem *voiceItem = voices.firstObject;
    NSString *voicePath = voiceItem.filePath;
    AVURLAsset *songAsset  = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:voicePath] options:nil];
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray<AVAssetTrack *> *audioTracks = [songAsset tracksWithMediaType:AVMediaTypeAudio];
    AVAssetTrack *sourceAudioTrack = nil;
    if ([audioTracks count] != 0) {
        sourceAudioTrack = audioTracks.firstObject;
    }

    NSError *error = nil;
    __block BOOL ok = NO;
    
//    CMTime startTime = start;
    CMTime trackDuration = songAsset.duration;
    CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, trackDuration);
    
    //Set Volume
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    [trackMix setVolume:0.8f atTime:kCMTimeZero];
    [self.audioMixParams addObject:trackMix];
    
    //Insert audio into track  //offset CMTimeMake(0, 44100)
    ok = [track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:voiceItem.startTime error:&error];
    [voices enumerateObjectsUsingBlock:^(VoiceItem *voiceItem, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            return;
        }
        NSString *audioPath = voiceItem.filePath;
        AVURLAsset *currentAudio = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioPath] options:nil];
        NSArray *tracks = [currentAudio tracksWithMediaType:AVMediaTypeAudio];
        
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        [trackMix setVolume:0.8f atTime:kCMTimeZero];
        [self.audioMixParams addObject:trackMix];
        
        if (tracks.count != 0) {
            ok = [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAudio.duration) ofTrack:tracks.firstObject atTime:voiceItem.startTime error:nil];
        }
    }];
    
    
}

@end
