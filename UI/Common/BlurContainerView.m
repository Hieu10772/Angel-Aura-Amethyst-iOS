#import "BlurContainerView.h"

@interface BlurContainerView ()
@property (nonatomic) UIVisualEffectView *blurView;
@property (nonatomic) UIView *tintView;
@end

@implementation BlurContainerView

- (instancetype)initWithBlurStyle:(UIBlurEffectStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _blurStyle = style;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.clipsToBounds = YES;

    self.blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.blurView];

    self.tintView = [[UIView alloc] init];
    self.tintView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tintView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
    self.tintView.userInteractionEnabled = NO;
    [self.blurView.contentView addSubview:self.tintView];

    [NSLayoutConstraint activateConstraints:@[
        [self.blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.tintView.topAnchor constraintEqualToAnchor:self.blurView.contentView.topAnchor],
        [self.tintView.leadingAnchor constraintEqualToAnchor:self.blurView.contentView.leadingAnchor],
        [self.tintView.trailingAnchor constraintEqualToAnchor:self.blurView.contentView.trailingAnchor],
        [self.tintView.bottomAnchor constraintEqualToAnchor:self.blurView.contentView.bottomAnchor],
    ]];
}

- (void)setBlurStyle:(UIBlurEffectStyle)blurStyle {
    _blurStyle = blurStyle;
    self.blurView.effect = nil;
}

@end
