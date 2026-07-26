#import "UIView+AmethystExtensions.h"
#import <objc/runtime.h>

@implementation UIView (AmethystExtensions)

- (CGFloat)amethyst_x { return self.frame.origin.x; }
- (void)setAmethyst_x:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)amethyst_y { return self.frame.origin.y; }
- (void)setAmethyst_y:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)amethyst_width { return self.frame.size.width; }
- (void)setAmethyst_width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)amethyst_height { return self.frame.size.height; }
- (void)setAmethyst_height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (void)amethyst_addShadowWithRadius:(CGFloat)radius opacity:(CGFloat)opacity offset:(CGSize)offset {
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = opacity;
    self.clipsToBounds = NO;
}

- (void)amethyst_addBorderWithColor:(UIColor *)color width:(CGFloat)width {
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
}

- (void)amethyst_roundCorners:(UIRectCorner)corners radius:(CGFloat)radius {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.path = path.CGPath;
    self.layer.mask = mask;
}

@end

@implementation UIImage (AmethystExtensions)

+ (UIImage *)amethyst_imageWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        [context fillRect:CGRectMake(0, 0, size.width, size.height)];
    }];
}

- (UIImage *)amethyst_tintedWithColor:(UIColor *)color {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:self.size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        [self drawAtPoint:CGPointZero];
        [context fillRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeSourceIn];
    }];
}

@end

@implementation UIColor (AmethystExtensions)

+ (UIColor *)amethyst_colorFromHex:(NSString *)hex {
    hex = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (hex.length == 6) {
        unsigned int rgb;
        [[NSScanner scannerWithString:hex] scanHexInt:&rgb];
        return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                               green:((rgb >> 8) & 0xFF) / 255.0
                                blue:(rgb & 0xFF) / 255.0
                               alpha:1.0];
    }
    return [UIColor clearColor];
}

- (NSString *)amethyst_hexString {
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"#%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

@end
