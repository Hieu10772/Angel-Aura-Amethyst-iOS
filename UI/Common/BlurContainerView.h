#import <UIKit/UIKit.h>

@interface BlurContainerView : UIView

@property (nonatomic) UIBlurEffectStyle blurStyle;

- (instancetype)initWithBlurStyle:(UIBlurEffectStyle)style;

@end
