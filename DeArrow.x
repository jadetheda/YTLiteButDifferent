#import "YTLite.h"
#import "Utils/DeArrowManager.h"

@interface YTIFormattedString : NSObject
@property (nonatomic, strong) NSMutableArray *runsArray;
- (NSString *)text;
@end

@interface YTIFormattedStringRun : NSObject
@property (nonatomic, strong) NSString *text;
@end

@interface YTIThumbnailDetails : NSObject
@property (nonatomic, strong) NSMutableArray *thumbnailsArray;
@end

@interface YTIThumbnailDetails_Thumbnail : NSObject
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) unsigned int width;
@property (nonatomic, assign) unsigned int height;
@end

// Helper to modify Title
static YTIFormattedString *modifyTitle(YTIFormattedString *titleObj, NSString *videoId) {
    if (!ytlBool(@"dearrowTitles")) return titleObj;
    
    NSString *originalTitle = [titleObj text];
    NSString *newTitle = [[DeArrowManager sharedManager] getReplacedTitleForVideoID:videoId originalTitle:originalTitle];
    
    if (newTitle && ![newTitle isEqualToString:originalTitle]) {
        YTIFormattedString *newObj = [[%c(YTIFormattedString) alloc] init];
        if ([newObj respondsToSelector:@selector(setRunsArray:)]) {
            YTIFormattedStringRun *run = [[%c(YTIFormattedStringRun) alloc] init];
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
            thumb.url = urlStr;
            thumb.width = 1280;
            thumb.height = 720;
            newObj.thumbnailsArray = [NSMutableArray arrayWithObject:thumb];
            return newObj;
        }
    }
    return thumbnailObj;
}

#define HOOK_RENDERER(Class) \
%hook Class \
- (id)title { return modifyTitle(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); } \
- (id)thumbnail { return modifyThumbnail(%orig, [self respondsToSelector:@selector(videoId)] ? [self performSelector:@selector(videoId)] : nil); } \
%end

HOOK_RENDERER(YTICompactVideoRenderer)
HOOK_RENDERER(YTIVideoRenderer)
HOOK_RENDERER(YTIGridVideoRenderer)
HOOK_RENDERER(YTIPlaylistVideoRenderer)

#define HOOK_CELL(Class) \
%hook Class \
- (void)setEntry:(id)entry { \
    %orig; \
    if (entry && [entry respondsToSelector:@selector(videoId)]) { \
        NSString *videoId = [entry performSelector:@selector(videoId)]; \
        if (videoId) { \
            [[DeArrowManager sharedManager] fetchDeArrowDataForVideoIDs:@[videoId] completion:^(BOOL updated) { \
                if (updated) { \
                    dispatch_async(dispatch_get_main_queue(), ^{ \
                        [self setEntry:entry]; \
                    }); \
                } \
            }]; \
        } \
    } \
} \
%end

HOOK_CELL(YTCompactVideoCell)
HOOK_CELL(YTVideoCell)
HOOK_CELL(YTGridVideoCell)
HOOK_CELL(YTPlaylistVideoCell)

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

