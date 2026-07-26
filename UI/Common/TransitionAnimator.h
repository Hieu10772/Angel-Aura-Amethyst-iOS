#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TransitionType) {
    TransitionTypeSlideFromRight,
    TransitionTypeSlideFromLeft,
    TransitionTypeFade,
    TransitionTypeSlideUp
};

@interface TransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) TransitionType transitionType;
@property (nonatomic) BOOL isPresenting;
@property (nonatomic) NSTimeInterval duration;

- (instancetype)initWithType:(TransitionType)type;

@end
