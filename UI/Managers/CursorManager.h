#import <UIKit/UIKit.h>
#import "CursorType.h"

NS_ASSUME_NONNULL_BEGIN

@interface CursorManager : NSObject

+ (NSString *)cursorsDirectory;
+ (NSString *)defaultCursorName;
+ (BOOL)isDefaultCursor:(NSString *)name;

/* All cursor names — kept for compatibility */
+ (NSArray<NSString *> *)cursorNames;

/* Cursor names belonging to a specific cursor type */
+ (NSArray<NSString *> *)cursorNamesForType:(CursorType)type;

+ (CursorType)cursorTypeForCursor:(NSString *)name;
+ (void)setCursor:(NSString *)name type:(CursorType)type;

+ (NSString *)currentCursorName;
+ (void)setCurrentCursorName:(NSString *)name;

+ (UIImage *)imageForCursor:(NSString *)name;

+ (CGPoint)hitboxForCursor:(NSString *)name;
+ (void)setHitboxForCursor:(NSString *)name hitbox:(CGPoint)hitbox;

+ (BOOL)deleteCursor:(NSString *)name;

+ (nullable NSString *)importCursorFromURL:(NSURL *)url
                                   withName:(NSString *)name
                                     error:(NSError **)error;

+ (nullable NSString *)importCursorFromURL:(NSURL *)url
                                   withName:(NSString *)name
                                      type:(CursorType)type
                                     error:(NSError **)error;

+ (nullable NSString *)importCursorFromImage:(UIImage *)image
                                     withName:(NSString *)name
                                       error:(NSError **)error;

+ (nullable NSString *)importCursorFromImage:(UIImage *)image
                                     withName:(NSString *)name
                                        type:(CursorType)type
                                       error:(NSError **)error;

+ (CGRect)displayFrameForMouseFrame:(CGRect)mouseFrame;
+ (CGRect)mouseFrameForDisplayFrame:(CGRect)displayFrame;

/* Cursor types */
+ (NSString *)normalCursorName;
+ (NSString *)handCursorName;
+ (NSString *)ibeamCursorName;
+ (NSString *)resizeEWCursorName;
+ (NSString *)resizeNSCursorName;

+ (void)setNormalCursorName:(NSString *)name;
+ (void)setHandCursorName:(NSString *)name;
+ (void)setIBeamCursorName:(NSString *)name;
+ (void)setResizeEWCursorName:(NSString *)name;
+ (void)setResizeNSCursorName:(NSString *)name;

+ (void)setCursorType:(CursorType)type;

@end

NS_ASSUME_NONNULL_END
