#import "YTLite.h"
#import "Utils/DeArrowManager.h"
#import "../YouTubeHeader/YTIFormattedString.h"
#import "../YouTubeHeader/YTIStringRun.h"
#import "../YouTubeHeader/YTIThumbnailDetails.h"
#import "../YouTubeHeader/YTIThumbnailDetails_Thumbnail.h"

@interface YTICompactVideoRenderer : NSObject
- (NSString *)videoId;
@end
@interface YTIVideoRenderer : NSObject
- (NSString *)videoId;
@end
@interface YTIGridVideoRenderer : NSObject
- (NSString *)videoId;
@end
@interface YTIPlaylistVideoRenderer : NSObject
- (NSString *)videoId;
@end
@interface YTCompactVideoCell : UIView
- (void)setEntry:(id)entry;
@end
@interface YTVideoCell : UIView
- (void)setEntry:(id)entry;
@end
@interface YTGridVideoCell : UIView
- (void)setEntry:(id)entry;
@end
@interface YTPlaylistVideoCell : UIView
- (void)setEntry:(id)entry;
@end
@interface YTIVideoDetails (DeArrow)
- (NSString *)videoId;
@end
@interface YTWatchViewController (DeArrow)
- (void)setVideoDetails:(id)videoDetails;
@end
@interface YTIFormattedString (DeArrow)
- (NSString *)text;
@end

// Helper to modify Title
static YTIFormattedString *modifyTitle(YTIFormattedString *titleObj, NSString *videoId) {
    if (!ytlBool(@"dearrowTitles")) return titleObj;
    
    NSString *originalTitle = [titleObj text];
    NSString *newTitle = [[DeArrowManager sharedManager] getReplacedTitleForVideoID:videoId originalTitle:originalTitle];
    
    if (newTitle && ![newTitle isEqualToString:originalTitle]) {
        YTIFormattedString *newObj = [[%c(YTIFormattedString) alloc] init];
        if ([newObj respondsToSelector:@selector(setRunsArray:)]) {
            YTIStringRun *run = [[%c(YTIStringRun) alloc] init];
            run.text = newTitle;
            newObj.runsArray = [NSMutableArray arrayWithObject:run];
            return newObj;
        }
    }
    return titleObj;
}

// Helper to modify Thumbnail
static YTIThumbnailDetails *modifyThumbnail(YTIThumbnailDetails *thumbnailObj, NSString *videoId) {
    if (!ytlBool(@"dearrowThumbnails")) return thumbnailObj;
    
    BOOL hasDeArrow = [[DeArrowManager sharedManager] hasReplacedThumbnailForVideoID:videoId];
    if (hasDeArrow) {
        NSString *urlStr = [NSString stringWithFormat:@"https://dearrow-thumb.ajay.app/api/v1/getThumbnail?videoID=%@", videoId];
        YTIThumbnailDetails *newObj = [[%c(YTIThumbnailDetails) alloc] init];
        if ([newObj respondsToSelector:@selector(setThumbnailsArray:)]) {
            YTIThumbnailDetails_Thumbnail *thumb = [[%c(YTIThumbnailDetails_Thumbnail) alloc] init];
            thumb.URL = urlStr;
            thumb.width = 1280;
            thumb.height = 720;
            newObj.thumbnailsArray = [NSMutableArray arrayWithObject:thumb];
            return newObj;
        }
    }
    return thumbnailObj;
}

%hook YTICompactVideoRenderer
- (id)title { return modifyTitle(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
- (id)thumbnail { return modifyThumbnail(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
%end

%hook YTIVideoRenderer
- (id)title { return modifyTitle(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
- (id)thumbnail { return modifyThumbnail(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
%end

%hook YTIGridVideoRenderer
- (id)title { return modifyTitle(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
- (id)thumbnail { return modifyThumbnail(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
%end

%hook YTIPlaylistVideoRenderer
- (id)title { return modifyTitle(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
- (id)thumbnail { return modifyThumbnail(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); }
%end

%hook YTCompactVideoCell
- (void)setEntry:(id)entry {
    %orig;
    if (entry && [entry respondsToSelector:@selector(videoId)]) {
        NSString *videoId = [entry performSelector:@selector(videoId)];
        if (videoId) {
            [[DeArrowManager sharedManager] fetchDeArrowDataForVideoIDs:@[videoId] completion:^(BOOL updated) {
                if (updated) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setEntry:entry];
                    });
                }
            }];
        }
    }
}
%end

%hook YTVideoCell
- (void)setEntry:(id)entry {
    %orig;
    if (entry && [entry respondsToSelector:@selector(videoId)]) {
        NSString *videoId = [entry performSelector:@selector(videoId)];
        if (videoId) {
            [[DeArrowManager sharedManager] fetchDeArrowDataForVideoIDs:@[videoId] completion:^(BOOL updated) {
                if (updated) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setEntry:entry];
                    });
                }
            }];
        }
    }
}
%end

%hook YTGridVideoCell
- (void)setEntry:(id)entry {
    %orig;
    if (entry && [entry respondsToSelector:@selector(videoId)]) {
        NSString *videoId = [entry performSelector:@selector(videoId)];
        if (videoId) {
            [[DeArrowManager sharedManager] fetchDeArrowDataForVideoIDs:@[videoId] completion:^(BOOL updated) {
                if (updated) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setEntry:entry];
                    });
                }
            }];
        }
    }
}
%end

%hook YTPlaylistVideoCell
- (void)setEntry:(id)entry {
    %orig;
    if (entry && [entry respondsToSelector:@selector(videoId)]) {
        NSString *videoId = [entry performSelector:@selector(videoId)];
        if (videoId) {
            [[DeArrowManager sharedManager] fetchDeArrowDataForVideoIDs:@[videoId] completion:^(BOOL updated) {
                if (updated) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setEntry:entry];
                    });
                }
            }];
        }
    }
}
%end

%hook YTIVideoDetails
- (NSString *)title {
    if (!ytlBool(@"dearrowTitles")) return %orig;
    NSString *origTitle = %orig;
    NSString *videoId = [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil;
    NSString *newTitle = [[DeArrowManager sharedManager] getReplacedTitleForVideoID:videoId originalTitle:origTitle];
    if (newTitle) return newTitle;
    return origTitle;
}
%end

// Hook Watch view header or player view controller to fetch video details?
%hook YTWatchViewController
- (void)setVideoDetails:(id)videoDetails {
    %orig;
    if (videoDetails && [videoDetails respondsToSelector:@selector(videoId)]) {
        NSString *videoId = [videoDetails performSelector:@selector(videoId)];
        if (videoId) {
            [[DeArrowManager sharedManager] fetchDeArrowDataForVideoIDs:@[videoId] completion:^(BOOL updated) {
                if (updated) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // update UI if needed.
                    });
                }
            }];
        }
    }
}
%end
