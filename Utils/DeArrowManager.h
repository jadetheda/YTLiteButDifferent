#import <Foundation/Foundation.h>

@interface DeArrowManager : NSObject
+ (instancetype)sharedManager;
- (NSString *)getReplacedTitleForVideoID:(NSString *)videoID originalTitle:(NSString *)originalTitle;
- (BOOL)hasReplacedThumbnailForVideoID:(NSString *)videoID;
- (void)fetchDeArrowDataForVideoIDs:(NSArray<NSString *> *)videoIDs completion:(void (^)(BOOL updated))completion;
@end
