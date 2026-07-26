#import <UIKit/UIKit.h>

extern NSString * const kLiquidGlassTag;

@interface UIView (LiquidGlass)

- (UIVisualEffectView *)lg_addGlassEffect;
- (UIVisualEffectView *)lg_addGlassEffectWithTint:(UIColor *)tintColor cornerRadius:(CGFloat)radius;
- (void)lg_removeGlassEffect;
- (BOOL)lg_hasGlassEffect;

@end
