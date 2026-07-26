#import "TransitionAnimator.h"

@implementation TransitionAnimator

- (instancetype)initWithType:(TransitionType)type {
    self = [super init];
    if (self) {
        _transitionType = type;
        _duration = 0.35;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return UIAccessibilityIsReduceMotionEnabled() ? 0.2 : self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;

    if (UIAccessibilityIsReduceMotionEnabled()) {
        toView.alpha = 0;
        [containerView addSubview:toView];
        [UIView animateWithDuration:0.2 animations:^{
            fromView.alpha = 0;
            toView.alpha = 1;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
        return;
    }

    CGRect initialFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect offScreenRight = CGRectMake(initialFrame.size.width, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
    CGRect offScreenLeft = CGRectMake(-initialFrame.size.width, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
    CGRect offScreenBottom = CGRectMake(initialFrame.origin.x, initialFrame.size.height, initialFrame.size.width, initialFrame.size.height);

    switch (self.transitionType) {
        case TransitionTypeSlideFromRight:
            toView.frame = self.isPresenting ? offScreenRight : offScreenLeft;
            break;
        case TransitionTypeSlideFromLeft:
            toView.frame = self.isPresenting ? offScreenLeft : offScreenRight;
            break;
        case TransitionTypeSlideUp:
            toView.frame = self.isPresenting ? offScreenBottom : offScreenBottom;
            break;
        case TransitionTypeFade:
            toView.alpha = 0;
            toView.frame = initialFrame;
            break;
    }

    [containerView addSubview:toView];

    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self.transitionType == TransitionTypeFade) {
            fromView.alpha = 0;
            toView.alpha = 1;
        } else {
            toView.frame = initialFrame;
            if (self.isPresenting) {
                fromView.transform = CGAffineTransformMakeScale(0.95, 0.95);
            } else {
                fromView.frame = self.transitionType == TransitionTypeSlideFromRight ? offScreenRight : offScreenLeft;
            }
        }
    } completion:^(BOOL finished) {
        fromView.transform = CGAffineTransformIdentity;
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
}

@end
