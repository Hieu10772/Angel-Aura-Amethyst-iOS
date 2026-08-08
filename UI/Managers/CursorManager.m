#import "CursorManager.h"
#import "LauncherPreferences.h"
#import <ImageIO/ImageIO.h>
#import <string.h>

static NSString *const kCursorsDirName = @"cursors";
static NSString *const kDefaultCursorName = @"default";
static NSString *const kCurrentCursorPrefKey = @"control.virtmouse_cursor";
static NSString *const kHitboxFileName = @"hitbox.json";

static NSString *const kImagePngName = @"image.png";
static NSString *const kImageGifName = @"image.gif";

@implementation CursorManager

+ (NSString *)cursorsDirectory {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [documents stringByAppendingPathComponent:kCursorsDirName];
    NSFileManager *fm = NSFileManager.defaultManager;
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
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
    return [self.cursorsDirectory stringByAppendingPathComponent:name];
}

+ (NSArray<NSString *> *)cursorNames {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray *content = [fm contentsOfDirectoryAtPath:self.cursorsDirectory error:nil];
    NSMutableArray *names = [NSMutableArray arrayWithObject:kDefaultCursorName];
    for (NSString *item in content) {
        if ([item hasPrefix:@"."]) continue;
        if ([item isEqualToString:kDefaultCursorName]) continue;
        BOOL isDir = NO;
        NSString *full = [self.cursorsDirectory stringByAppendingPathComponent:item];
        if ([fm fileExistsAtPath:full isDirectory:&isDir] && isDir) {
            [names addObject:item];
        }
    }
    return names;
}

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

// The actual image file name stored in a cursor folder.
+ (NSString *)imageFileNameForCursor:(NSString *)name {
    NSString *dir = [self cursorPathForName:name];
    NSFileManager *fm = NSFileManager.defaultManager;
    if ([fm fileExistsAtPath:[dir stringByAppendingPathComponent:kImageGifName]]) {
        return kImageGifName;
    }
    return kImagePngName;
}

+ (NSString *)imagePathForCursor:(NSString *)name {
    return [[self cursorPathForName:name] stringByAppendingPathComponent:[self imageFileNameForCursor:name]];
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

+ (void)saveImageData:(NSData *)data isGIF:(BOOL)isGIF forCursor:(NSString *)name {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *dir = [self cursorPathForName:name];
    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName = isGIF ? kImageGifName : kImagePngName;
    [data writeToFile:[dir stringByAppendingPathComponent:fileName] atomically:YES];
}

#pragma mark - Hitbox

+ (NSString *)hitboxPathForCursor:(NSString *)name {
    return [[self cursorPathForName:name] stringByAppendingPathComponent:kHitboxFileName];
}

+ (CGPoint)hitboxForCursor:(NSString *)name {
    NSString *path = [self hitboxPathForCursor:name];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return CGPointZero;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![json isKindOfClass:NSDictionary.class]) return CGPointZero;
    return CGPointMake([json[@"x"] floatValue], [json[@"y"] floatValue]);
}

+ (void)setHitboxForCursor:(NSString *)name hitbox:(CGPoint)hitbox {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *dir = [self cursorPathForName:name];
    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *path = [dir stringByAppendingPathComponent:kHitboxFileName];
    NSDictionary *json = @{@"x": @(roundf(hitbox.x)), @"y": @(roundf(hitbox.y))};
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    [data writeToFile:path atomically:YES];
}

#pragma mark - Delete

+ (BOOL)deleteCursor:(NSString *)name {
    if ([self isDefaultCursor:name]) return NO;
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *dir = [self cursorPathForName:name];
    if (![fm fileExistsAtPath:dir]) return NO;
    return [fm removeItemAtPath:dir error:nil];
}

#pragma mark - Import

+ (NSString *)sanitizedName:(NSString *)name {
    if (!name || name.length == 0) name = @"Cursor";
    NSMutableCharacterSet *illegal = [NSMutableCharacterSet characterSetWithCharactersInString:@"/\\:*?\"<>|"];
    NSString *cleaned = [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"-"];
    cleaned = [cleaned stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return cleaned.length ? cleaned : @"Cursor";
}

+ (NSString *)uniqueCursorNameFor:(NSString *)name {
    NSString *base = [self sanitizedName:name];
    NSString *candidate = base;
    NSArray *existing = [self cursorNames];
    NSInteger i = 2;
    while ([existing containsObject:candidate]) {
        candidate = [NSString stringWithFormat:@"%@-%ld", base, (long)i++];
    }
    return candidate;
}

+ (NSString *)importCursorFromURL:(NSURL *)url withName:(NSString *)name error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) return nil;
    return [self importCursorFromData:data withName:name error:error];
}

+ (NSString *)importCursorFromImage:(UIImage *)image withName:(NSString *)name error:(NSError **)error {
    NSData *png = UIImagePNGRepresentation(image);
    if (!png) {
        if (error) *error = [NSError errorWithDomain:@"CursorManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to convert image"}];
        return nil;
    }
    return [self importCursorFromData:png withName:name error:error];
}

+ (NSString *)importCursorFromData:(NSData *)data withName:(NSString *)name error:(NSError **)error {
    NSString *cursor = [self uniqueCursorNameFor:name];
    BOOL isGIF = [self isAnimatedGIFData:data];
    if (!isGIF) {
        UIImage *img = [UIImage imageWithData:data];
        if (!img) {
            if (error) *error = [NSError errorWithDomain:@"CursorManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unsupported image format"}];
            return nil;
        }
        NSData *png = UIImagePNGRepresentation(img);
        data = png ?: data;
    }
    [self saveImageData:data isGIF:isGIF forCursor:cursor];
    return cursor;
}

+ (BOOL)isAnimatedGIFData:(NSData *)data {
    if (data.length < 6) return NO;
    const char *bytes = (const char *)data.bytes;
    return memcmp(bytes, "GIF8", 4) == 0;
}

+ (BOOL)isAnimatedData:(NSData *)data {
    return [self isAnimatedGIFData:data];
}

#pragma mark - Display

+ (CGFloat)displayScaleForImage:(UIImage *)image mouseScale:(CGFloat)mouseScale {
    if (!image) return mouseScale;
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    if (w <= 0 || h <= 0) return mouseScale;
    // Default pointer rendered at 18x27 with scale=1; custom images are scaled to
    // a comparable size so the pointer stays usable on screen.
    // Keep the height the same as default (27 * mouseScale).
    return (27.0 * mouseScale) / h;
}

+ (CGRect)displayFrameForMouseFrame:(CGRect)mouseFrame {
    NSString *name = self.currentCursorName;
    UIImage *image = [self imageForCursor:name];
    CGPoint hitbox = [self hitboxForCursor:name];

    CGFloat mouseScale = getPrefFloat(@"control.mouse_scale") / 100.0;
    CGFloat scale = [self displayScaleForImage:image mouseScale:mouseScale];
    CGSize displaySize = CGSizeMake(image.size.width * scale, image.size.height * scale);

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
    NSString *name = self.currentCursorName;
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