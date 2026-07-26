#import "UIView+LiquidGlass.h"
#import <objc/runtime.h>

NSString * const kLiquidGlassTag = @"__lg_glass_view";

static void * const kLiquidGlassKey = (void*)&kLiquidGlassKey;

@implementation UIView (LiquidGlass)

- (UIVisualEffectView *)lg_addGlassEffect {
    return [self lg_addGlassEffectWithTint:[UIColor colorWithWhite:1 alpha:0.1] cornerRadius:14];
}

- (UIVisualEffectView *)lg_addGlassEffectWithTint:(UIColor *)tintColor cornerRadius:(CGFloat)radius {
    if ([self lg_hasGlassEffect]) {
        [self lg_removeGlassEffect];
    }

    self.layer.cornerRadius = radius;
    self.clipsToBounds = YES;

    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:nil];
    effectView.translatesAutoresizingMaskIntoConstraints = NO;
    effectView.layer.cornerRadius = radius;
    effectView.clipsToBounds = YES;
    effectView.userInteractionEnabled = NO;

    Class glassClass = NSClassFromString(@"UIGlassEffect");
    if (glassClass) {
        id glass = [[glassClass alloc] init];
        if (tintColor) {
            [glass setTintColor:tintColor];
        }
        effectView.effect = glass;
    } else {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.translatesAutoresizingMaskIntoConstraints = NO;
        blurView.layer.cornerRadius = radius;
        blurView.clipsToBounds = YES;
        blurView.userInteractionEnabled = NO;

        UIView *tintOverlay = [[UIView alloc] init];
        tintOverlay.translatesAutoresizingMaskIntoConstraints = NO;
        tintOverlay.backgroundColor = tintColor;
        tintOverlay.userInteractionEnabled = NO;
        [blurView.contentView addSubview:tintOverlay];

        [effectView.contentView addSubview:blurView];
        [NSLayoutConstraint activateConstraints:@[
            [blurView.topAnchor constraintEqualToAnchor:effectView.contentView.topAnchor],
            [blurView.leadingAnchor constraintEqualToAnchor:effectView.contentView.leadingAnchor],
            [blurView.trailingAnchor constraintEqualToAnchor:effectView.contentView.trailingAnchor],
            [blurView.bottomAnchor constraintEqualToAnchor:effectView.contentView.bottomAnchor],
            [tintOverlay.topAnchor constraintEqualToAnchor:blurView.contentView.topAnchor],
            [tintOverlay.leadingAnchor constraintEqualToAnchor:blurView.contentView.leadingAnchor],
            [tintOverlay.trailingAnchor constraintEqualToAnchor:blurView.contentView.trailingAnchor],
            [tintOverlay.bottomAnchor constraintEqualToAnchor:blurView.contentView.bottomAnchor],
        ]];
    }

    [self insertSubview:effectView atIndex:0];

    [NSLayoutConstraint activateConstraints:@[
        [effectView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [effectView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [effectView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [effectView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    self.backgroundColor = [UIColor clearColor];

    objc_setAssociatedObject(self, kLiquidGlassKey, effectView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return effectView;
}

- (void)lg_removeGlassEffect {
    UIVisualEffectView *blurView = objc_getAssociatedObject(self, kLiquidGlassKey);
    [blurView removeFromSuperview];
    objc_setAssociatedObject(self, kLiquidGlassKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)lg_hasGlassEffect {
    return objc_getAssociatedObject(self, kLiquidGlassKey) != nil;
}

@end
