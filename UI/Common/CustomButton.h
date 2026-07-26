#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CustomButtonStyle) {
    CustomButtonStylePrimary,
    CustomButtonStyleSecondary,
    CustomButtonStyleDestructive,
    CustomButtonStyleGhost
};

@interface CustomButton : UIButton

@property (nonatomic) CustomButtonStyle buttonStyle;
@property (nonatomic) CGFloat cornerRadius;

- (instancetype)initWithStyle:(CustomButtonStyle)style title:(NSString *)title;

@end
