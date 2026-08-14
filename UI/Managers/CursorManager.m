#import "CursorManager.h"
#import "LauncherPreferences.h"
#import <ImageIO/ImageIO.h>
#import <string.h>

static NSString * const kNormalCursorKey   = @"normal_cursor";
static NSString * const kHandCursorKey     = @"hand_cursor";
static NSString * const kIBeamCursorKey    = @"ibeam_cursor";
static NSString * const kResizeEWCursorKey = @"resize_ew_cursor";
static NSString * const kResizeNSCursorKey = @"resize_ns_cursor";

static NSString *const kCursorsDirName = @"cursors";
static NSString *const kDefaultCursorName = @"default";
static NSString *const kCurrentCursorPrefKey = @"control.virtmouse_cursor";
static NSString *const kHitboxFileName = @"hitbox.json";

static NSString *const kImagePngName = @"image.png";
static NSString *const kImageGifName = @"image.gif";

@implementation CursorManager

#pragma mark - Directories

+ (NSString *)cursorsDirectory {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [documents stringByAppendingPathComponent:kCursorsDirName];

    NSFileManager *fm = NSFileManager.defaultManager;
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    }

    return path;
}

+ (NSString *)defaultCursorName {
    return kDefaultCursorName;
}

+ (BOOL)isDefaultCursor:(NSString *)name {
    return [name isEqualToString:kDefaultCursorName];
}

+ (NSString *)cursorPathForName:(NSString *)name {
    return [[self cursorsDirectory] stringByAppendingPathComponent:name];
}

#pragma mark - Cursor List

+ (NSArray<NSString *> *)cursorNames {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray *content = [fm contentsOfDirectoryAtPath:[self cursorsDirectory]
                                                   error:nil];

    NSMutableArray *names = [NSMutableArray arrayWithObject:kDefaultCursorName];

    for (NSString *item in content) {
        if ([item hasPrefix:@"."]) continue;
        if ([item isEqualToString:kDefaultCursorName]) continue;

        BOOL isDir = NO;
        NSString *full = [[self cursorsDirectory] stringByAppendingPathComponent:item];

        if ([fm fileExistsAtPath:full isDirectory:&isDir] && isDir) {
            [names addObject:item];
        }
    }

    return names;
}

#pragma mark - Current Cursor

+ (NSString *)currentCursorName {
    id name = getPrefObject(kCurrentCursorPrefKey);

    if (![name isKindOfClass:NSString.class] || [name length] == 0) {
        return kDefaultCursorName;
    }

    return name;
}

+ (void)setCurrentCursorName:(NSString *)name {
    setPrefObject(kCurrentCursorPrefKey, name);
}

#pragma mark - Image

+ (NSString *)imageFileNameForCursor:(NSString *)name {
    NSString *dir = [self cursorPathForName:name];
    NSFileManager *fm = NSFileManager.defaultManager;

    if ([fm fileExistsAtPath:[dir stringByAppendingPathComponent:kImageGifName]]) {
        return kImageGifName;
    }

    return kImagePngName;
}

+ (NSString *)imagePathForCursor:(NSString *)name {
    return [[self cursorPathForName:name]
        stringByAppendingPathComponent:[self imageFileNameForCursor:name]];
}

+ (UIImage *)imageForCursor:(NSString *)name {
    if ([self isDefaultCursor:name]) {
        return [UIImage imageNamed:@"MousePointer"];
    }

    NSString *path = [self imagePathForCursor:name];

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [UIImage imageWithContentsOfFile:path];
    }

    return [UIImage imageNamed:@"MousePointer"];
}

#pragma mark - Cursor Types

+ (NSString *)normalCursorName {
    return [[NSUserDefaults standardUserDefaults]
        stringForKey:kNormalCursorKey] ?: @"default";
}

+ (void)setNormalCursorName:(NSString *)name {
    [[NSUserDefaults standardUserDefaults]
        setObject:name forKey:kNormalCursorKey];
}

+ (NSString *)handCursorName {
    return [[NSUserDefaults standardUserDefaults]
        stringForKey:kHandCursorKey] ?: @"hand";
}

+ (void)setHandCursorName:(NSString *)name {
    [[NSUserDefaults standardUserDefaults]
        setObject:name forKey:kHandCursorKey];
}

+ (NSString *)ibeamCursorName {
    return [[NSUserDefaults standardUserDefaults]
        stringForKey:kIBeamCursorKey] ?: @"text";
}

+ (void)setIBeamCursorName:(NSString *)name {
    [[NSUserDefaults standardUserDefaults]
        setObject:name forKey:kIBeamCursorKey];
}

+ (NSString *)resizeEWCursorName {
    return [[NSUserDefaults standardUserDefaults]
        stringForKey:kResizeEWCursorKey] ?: @"resize_ew";
}

+ (void)setResizeEWCursorName:(NSString *)name {
    [[NSUserDefaults standardUserDefaults]
        setObject:name forKey:kResizeEWCursorKey];
}

+ (NSString *)resizeNSCursorName {
    return [[NSUserDefaults standardUserDefaults]
        stringForKey:kResizeNSCursorKey] ?: @"resize_ns";
}

+ (void)setResizeNSCursorName:(NSString *)name {
    [[NSUserDefaults standardUserDefaults]
        setObject:name forKey:kResizeNSCursorKey];
}

#pragma mark - Auto Switching

+ (void)setCursorType:(CursorType)type {
    switch (type) {
        case CursorTypeHand:
            [self setCurrentCursorName:[self handCursorName]];
            break;

        case CursorTypeIBeam:
            [self setCurrentCursorName:[self ibeamCursorName]];
            break;

        case CursorTypeResizeEW:
            [self setCurrentCursorName:[self resizeEWCursorName]];
            break;

        case CursorTypeResizeNS:
            [self setCurrentCursorName:[self resizeNSCursorName]];
            break;

        case CursorTypeNormal:
        default:
            [self setCurrentCursorName:[self normalCursorName]];
            break;
    }
}

#pragma mark - Hitbox

+ (NSString *)hitboxPathForCursor:(NSString *)name {
    return [[self cursorPathForName:name] stringByAppendingPathComponent:kHitboxFileName];
}

+ (CGPoint)hitboxForCursor:(NSString *)name {
    NSString *path = [self hitboxPathForCursor:name];
    NSData *data = [NSData dataWithContentsOfFile:path];

    if (!data) return CGPointZero;

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:nil];

    if (![json isKindOfClass:NSDictionary.class]) return CGPointZero;

    return CGPointMake([json[@"x"] floatValue],
                       [json[@"y"] floatValue]);
}

+ (void)setHitboxForCursor:(NSString *)name hitbox:(CGPoint)hitbox {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *dir = [self cursorPathForName:name];

    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    }

    NSString *path = [dir stringByAppendingPathComponent:kHitboxFileName];

    NSDictionary *json = @{
        @"x": @(roundf(hitbox.x)),
        @"y": @(roundf(hitbox.y))
    };

    NSData *data = [NSJSONSerialization dataWithJSONObject:json
                                                       options:0
                                                         error:nil];

    [data writeToFile:path atomically:YES];
}

#pragma mark - Display

+ (CGFloat)displayScaleForImage:(UIImage *)image mouseScale:(CGFloat)mouseScale {
    if (!image) return mouseScale;

    CGFloat h = image.size.height;
    if (h <= 0) return mouseScale;

    return (27.0 * mouseScale) / h;
}

+ (CGRect)displayFrameForMouseFrame:(CGRect)mouseFrame {
    NSString *name = [self currentCursorName];
    UIImage *image = [self imageForCursor:name];
    CGPoint hitbox = [self hitboxForCursor:name];

    CGFloat mouseScale = getPrefFloat(@"control.mouse_scale") / 100.0;
    CGFloat scale = [self displayScaleForImage:image mouseScale:mouseScale];

    CGSize displaySize = CGSizeMake(image.size.width * scale,
                                    image.size.height * scale);

    CGFloat imgW = MAX(image.size.width, 1);
    CGFloat imgH = MAX(image.size.height, 1);

    CGFloat dispX = (hitbox.x / imgW) * displaySize.width;
    CGFloat dispY = (hitbox.y / imgH) * displaySize.height;

    CGRect frame = mouseFrame;
    frame.origin.x -= dispX;
    frame.origin.y -= dispY;
    frame.size = displaySize;

    return frame;
}

+ (CGRect)mouseFrameForDisplayFrame:(CGRect)displayFrame {
    NSString *name = [self currentCursorName];
    UIImage *image = [self imageForCursor:name];
    CGPoint hitbox = [self hitboxForCursor:name];

    CGFloat imgW = MAX(image.size.width, 1);
    CGFloat imgH = MAX(image.size.height, 1);

    CGFloat dispX = (hitbox.x / imgW) * displayFrame.size.width;
    CGFloat dispY = (hitbox.y / imgH) * displayFrame.size.height;

    CGRect frame = displayFrame;
    frame.origin.x += dispX;
    frame.origin.y += dispY;

    return frame;
}

@end
