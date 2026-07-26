#import <UIKit/UIKit.h>

@interface UIView (AmethystExtensions)

@property (nonatomic) CGFloat amethyst_x;
@property (nonatomic) CGFloat amethyst_y;
@property (nonatomic) CGFloat amethyst_width;
@property (nonatomic) CGFloat amethyst_height;

- (void)amethyst_addShadowWithRadius:(CGFloat)radius opacity:(CGFloat)opacity offset:(CGSize)offset;
- (void)amethyst_addBorderWithColor:(UIColor *)color width:(CGFloat)width;
- (void)amethyst_roundCorners:(UIRectCorner)corners radius:(CGFloat)radius;

@end

@interface UIImage (AmethystExtensions)

+ (UIImage *)amethyst_imageWithColor:(UIColor *)color size:(CGSize)size;
- (UIImage *)amethyst_tintedWithColor:(UIColor *)color;

@end

@interface UIColor (AmethystExtensions)

+ (UIColor *)amethyst_colorFromHex:(NSString *)hex;
- (NSString *)amethyst_hexString;

@end
