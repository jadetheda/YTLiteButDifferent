#import "DeArrowManager.h"
#import "../YTLite.h"
#import <UIKit/UIKit.h>

@interface DeArrowManager ()
@property (nonatomic, strong) NSMutableDictionary *titleCache;
@property (nonatomic, strong) NSMutableDictionary *thumbnailCache;
@property (nonatomic, strong) NSMutableSet *fetchingVideoIDs;
@end

@implementation DeArrowManager

+ (instancetype)sharedManager {
    static DeArrowManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[DeArrowManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _titleCache = [NSMutableDictionary dictionary];
        _thumbnailCache = [NSMutableDictionary dictionary];
        _fetchingVideoIDs = [NSMutableSet set];
    }
    return self;
}

- (NSString *)formatTitle:(NSString *)originalTitle {
    if (!originalTitle || originalTitle.length == 0) return originalTitle;
    if (ytlBool(@"dearrowFormatTitles")) {
        return [originalTitle capitalizedString];
    }
    return originalTitle;
}

- (NSString *)getReplacedTitleForVideoID:(NSString *)videoID originalTitle:(NSString *)originalTitle {
    if (!videoID) return [self formatTitle:originalTitle];
    NSString *cached;
    @synchronized (self) {
        cached = self.titleCache[videoID];
    }
    if (cached) {
        return [cached isEqualToString:@""] ? [self formatTitle:originalTitle] : cached;
    }
    return [self formatTitle:originalTitle];
}

- (BOOL)hasReplacedThumbnailForVideoID:(NSString *)videoID {
    if (!videoID) return NO;
    NSNumber *cached;
    @synchronized (self) {
        cached = self.thumbnailCache[videoID];
    }
    if (cached) {
        return [cached boolValue];
    }
    return NO;
}

- (void)fetchDeArrowDataForVideoIDs:(NSArray<NSString *> *)videoIDs completion:(void (^)(BOOL updated))completion {
    if (!ytlBool(@"dearrowTitles") && !ytlBool(@"dearrowThumbnails")) {
        if (completion) completion(NO);
        return;
    }

    NSMutableArray *toFetch = [NSMutableArray array];
    @synchronized (self) {
        for (NSString *videoID in videoIDs) {
            if (![self.titleCache objectForKey:videoID] && ![self.fetchingVideoIDs containsObject:videoID]) {
                [toFetch addObject:videoID];
                [self.fetchingVideoIDs addObject:videoID];
            }
        }
    }
    
    if (toFetch.count == 0) {
        if (completion) completion(NO);
        return;
    }
    
    NSString *videoIDsString = [toFetch componentsJoinedByString:@","];
    NSString *urlString = [NSString stringWithFormat:@"https://sponsor.ajay.app/api/branding?videoIDs=%@", videoIDsString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BOOL updated = NO;
        if (data && !error) {
            NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json isKindOfClass:[NSArray class]]) {
                @synchronized (self) {
                    for (NSDictionary *videoData in json) {
                        NSString *videoID = videoData[@"videoID"];
                        if (!videoID) continue;
                        
                        NSArray *titles = videoData[@"titles"];
                        if (titles && [titles isKindOfClass:[NSArray class]] && titles.count > 0) {
                            NSDictionary *titleDict = titles.firstObject;
                            if (titleDict[@"title"]) {
                                self.titleCache[videoID] = titleDict[@"title"];
                                updated = YES;
                            }
                        } else {
                            self.titleCache[videoID] = @""; // Empty marks as fetched but no DeArrow title
                        }
                        
                        NSArray *thumbnails = videoData[@"thumbnails"];
                        if (thumbnails && [thumbnails isKindOfClass:[NSArray class]] && thumbnails.count > 0) {
                            self.thumbnailCache[videoID] = @(YES);
                            updated = YES;
                        } else {
                            self.thumbnailCache[videoID] = @(NO);
                        }
                    }
                }
            }
        }
        @synchronized (self) {
            [self.fetchingVideoIDs minusSet:[NSSet setWithArray:toFetch]];
            // Mark failed ones as empty so we don't retry forever
            for (NSString *vid in toFetch) {
                if (!self.titleCache[vid]) {
                    self.titleCache[vid] = @"";
                }
                if (!self.thumbnailCache[vid]) {
                    self.thumbnailCache[vid] = @(NO);
                }
            }
        }
        if (completion) completion(updated);
    }] resume];
}

@end
