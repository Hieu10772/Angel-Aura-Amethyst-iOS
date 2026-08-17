#import "CursorManager.h"
#import "LauncherPreferences.h"
#import <ImageIO/ImageIO.h>
#import <string.h>
#import <stdlib.h>

static NSString * const kNormalCursorKey   = @"normal_cursor";
static NSString * const kHandCursorKey     = @"hand_cursor";
static NSString * const kIBeamCursorKey    = @"ibeam_cursor";
static NSString * const kResizeEWCursorKey = @"resize_ew_cursor";
static NSString * const kResizeNSCursorKey = @"resize_ns_cursor";

static NSString *const kCursorsDirName = @"cursors";
static NSString *const kDefaultCursorName = @"default";
static NSString *const kCurrentCursorPrefKey = @"control.virtmouse_cursor";
static NSString *const kHitboxFileName = @"hitbox.json";
static NSString *const kCursorTypeFileName = @"type";

static NSString *const kImagePngName = @"image.png";
static NSString *const kImageGifName = @"image.gif";

@implementation CursorManager

+ (NSString *)cursorsDirectory {
    const char *gameDir = getenv("POJAV_GAME_DIR");

    if (!gameDir || gameDir[0] == '\0') {
        NSLog(@"[CursorManager] ERROR: POJAV_GAME_DIR is not set");
        return nil;
    }

    NSString *gamePath = [NSString stringWithUTF8String:gameDir];
    
    NSString *instancesPath = [gamePath stringByDeletingLastPathComponent];
    NSString *path = [instancesPath stringByAppendingPathComponent:kCursorsDirName];

    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL isDirectory = NO;

    if (![fm fileExistsAtPath:path isDirectory:&isDirectory]) {
        NSError *error = nil;
        BOOL created = [fm createDirectoryAtPath:path
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error];

        if (!created) {
            NSLog(@"[CursorManager] Failed to create cursors directory: %@",
                  error.localizedDescription);
            return nil;
        }
    } else if (!isDirectory) {
        NSLog(@"[CursorManager] ERROR: cursor path exists but is not a directory: %@",
              path);
        return nil;
    }

    NSLog(@"[CursorManager] Cursors directory: %@", path);
    return path;
}

+ (NSString *)defaultCursorName {
    return kDefaultCursorName;
}

+ (BOOL)isDefaultCursor:(NSString *)name {
    return [name isEqualToString:kDefaultCursorName];
}

+ (NSString *)cursorPathForName:(NSString *)name {
    NSString *directory = [self cursorsDirectory];

    if (!directory || !name || name.length == 0) {
        return nil;
    }

    return [directory stringByAppendingPathComponent:name];
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

+ (CursorType)cursorTypeForCursor:(NSString *)name {
    if ([name isEqualToString:kDefaultCursorName]) {
        return CursorTypeNormal;
    }

    NSString *path = [[self cursorPathForName:name]
                      stringByAppendingPathComponent:kCursorTypeFileName];

    NSString *value = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];

    NSInteger type = value.integerValue;

    if (type < CursorTypeNormal || type > CursorTypeResizeNS) {
        return CursorTypeNormal;
    }

    return (CursorType)type;
}

+ (void)setCursor:(NSString *)name type:(CursorType)type {

    if (!name || name.length == 0) {
        return;
    }

    if ([name isEqualToString:kDefaultCursorName] ||
        [name isEqualToString:@"hand"] ||
        [name isEqualToString:@"text"] ||
        [name isEqualToString:@"resize_ew"] ||
        [name isEqualToString:@"resize_ns"]) {
        NSLog(@"[CursorManager] Refusing to create files for built-in cursor: %@", name);
        return;
    }

    NSString *dir = [self cursorPathForName:name];

    if (!dir) {
        NSLog(@"[CursorManager] setCursor: invalid directory");
        return;
    }

    NSFileManager *fm = NSFileManager.defaultManager;

    if (![fm fileExistsAtPath:dir]) {
        NSError *createError = nil;

        BOOL created =
            [fm createDirectoryAtPath:dir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&createError];

        if (!created) {
            NSLog(@"[CursorManager] Failed to create cursor directory %@: %@",
                  dir,
                  createError.localizedDescription);
            return;
        }
    }

    NSString *path = [dir stringByAppendingPathComponent:kCursorTypeFileName];

    NSString *value = [NSString stringWithFormat:@"%ld", (long)type];

    NSError *writeError = nil;

    BOOL written =
        [value writeToFile:path
                atomically:YES
                  encoding:NSUTF8StringEncoding
                     error:&writeError];

    if (!written) {
        NSLog(@"[CursorManager] Failed to write cursor type: %@",
              writeError.localizedDescription);
    } else {
        NSLog(@"[CursorManager] Cursor type saved: %@ -> %ld",
              path,
              (long)type);
    }
}

+ (NSArray<NSString *> *)cursorNamesForType:(CursorType)type {
    NSFileManager *fm = NSFileManager.defaultManager;

    NSArray *content =
        [fm contentsOfDirectoryAtPath:self.cursorsDirectory error:nil];

    NSMutableArray<NSString *> *names = [NSMutableArray array];

    /*
     * Built-in cursors.
     * They belong to their corresponding cursor type.
     */
    switch (type) {
        case CursorTypeNormal:
            [names addObject:kDefaultCursorName];
            break;

        case CursorTypeHand:
            [names addObject:@"hand"];
            break;

        case CursorTypeIBeam:
            [names addObject:@"text"];
            break;

        case CursorTypeResizeEW:
            [names addObject:@"resize_ew"];
            break;

        case CursorTypeResizeNS:
            [names addObject:@"resize_ns"];
            break;
    }

    for (NSString *item in content) {
        if ([item hasPrefix:@"."]) {
            continue;
        }

        if ([item isEqualToString:kDefaultCursorName] ||
            [item isEqualToString:@"hand"] ||
            [item isEqualToString:@"text"] ||
            [item isEqualToString:@"resize_ew"] ||
            [item isEqualToString:@"resize_ns"]) {
            continue;
        }

        NSString *full =
            [self.cursorsDirectory stringByAppendingPathComponent:item];

        BOOL isDir = NO;

        if (![fm fileExistsAtPath:full isDirectory:&isDir] || !isDir) {
            continue;
        }

        if ([self cursorTypeForCursor:item] == type) {
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
    
    if ([name isEqualToString:@"hand"]) {
        return [UIImage imageNamed:@"HandPointer"] ?: [UIImage imageNamed:@"MousePointer"];
    }
    if ([name isEqualToString:@"text"]) {
        return [UIImage imageNamed:@"IBeamPointer"] ?: [UIImage imageNamed:@"MousePointer"];
    }
    if ([name isEqualToString:@"resize_ew"]) {
        return [UIImage imageNamed:@"ResizeEWPointer"] ?: [UIImage imageNamed:@"MousePointer"];
    }
    if ([name isEqualToString:@"resize_ns"]) {
        return [UIImage imageNamed:@"ResizeNSPointer"] ?: [UIImage imageNamed:@"MousePointer"];
    }
    
    NSString *path = [self imagePathForCursor:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [UIImage imageWithContentsOfFile:path];
    }
    
    return [UIImage imageNamed:@"MousePointer"];
}


+ (void)saveImageData:(NSData *)data
               isGIF:(BOOL)isGIF
            forCursor:(NSString *)name {

    if (!data || data.length == 0) {
        NSLog(@"[CursorManager] saveImageData: empty data");
        return;
    }

    if ([self isDefaultCursor:name]) {
    NSLog(@"[CursorManager] Refusing to create files for default cursor");
    return;
}

NSString *dir = [self cursorPathForName:name];

    if (!dir) {
        NSLog(@"[CursorManager] saveImageData: invalid directory");
        return;
    }

    NSFileManager *fm = NSFileManager.defaultManager;

    if (![fm fileExistsAtPath:dir]) {
        NSError *error = nil;

        BOOL created =
            [fm createDirectoryAtPath:dir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];

        if (!created) {
            NSLog(@"[CursorManager] Failed to create %@: %@",
                  dir,
                  error.localizedDescription);
            return;
        }
    }

    NSString *fileName = isGIF ? kImageGifName : kImagePngName;
    NSString *path = [dir stringByAppendingPathComponent:fileName];

    NSError *error = nil;

    BOOL written = [data writeToFile:path
                             options:NSDataWritingAtomic
                               error:&error];

    if (!written) {
        NSLog(@"[CursorManager] Failed to save image %@: %@",
              path,
              error.localizedDescription);
    } else {
        NSLog(@"[CursorManager] Cursor image saved: %@", path);
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
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![json isKindOfClass:NSDictionary.class]) return CGPointZero;
    return CGPointMake([json[@"x"] floatValue], [json[@"y"] floatValue]);
}

+ (void)setHitboxForCursor:(NSString *)name hitbox:(CGPoint)hitbox {

    if (!name || name.length == 0 || [self isDefaultCursor:name]) {
        NSLog(@"[CursorManager] Refusing to create hitbox for default cursor");
        return;
    }

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

    NSData *data =
        [NSJSONSerialization dataWithJSONObject:json
                                        options:0
                                          error:nil];

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

    if ([base isEqualToString:kDefaultCursorName]) {
        base = @"Cursor";
    }
    NSString *candidate = base;
    NSArray *existing = [self cursorNames];
    NSInteger i = 2;
    while ([existing containsObject:candidate]) {
        candidate = [NSString stringWithFormat:@"%@-%ld", base, (long)i++];
    }
    return candidate;
}

+ (NSString *)importCursorFromURL:(NSURL *)url
                         withName:(NSString *)name
                             type:(CursorType)type
                            error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url
                                         options:0
                                           error:error];

    if (!data) {
        return nil;
    }

    NSString *cursor =
        [self importCursorFromData:data
                          withName:name
                              error:error];

    if (cursor) {
        [self setCursor:cursor type:type];
    }

    return cursor;
}

+ (NSString *)importCursorFromImage:(UIImage *)image
                           withName:(NSString *)name
                              error:(NSError **)error {
    if (!image) {
        if (error) {
            *error = [NSError errorWithDomain:@"CursorManager" 
                                         code:-1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid image"}];
        }
        return nil;
    }
    
    NSData *pngData = UIImagePNGRepresentation(image);
    if (!pngData) {
        if (error) {
            *error = [NSError errorWithDomain:@"CursorManager" 
                                         code:-1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to convert image to PNG data"}];
        }
        return nil;
    }
    
    return [self importCursorFromData:pngData withName:name error:error];
}

+ (NSString *)importCursorFromImage:(UIImage *)image
                           withName:(NSString *)name
                              type:(CursorType)type
                             error:(NSError **)error {
    NSString *cursor =
        [self importCursorFromImage:image
                           withName:name
                             error:error];

    if (cursor) {
        [self setCursor:cursor type:type];
    }

    return cursor;
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

        default:
            [self setCurrentCursorName:[self normalCursorName]];
            break;
    }
}

@end
