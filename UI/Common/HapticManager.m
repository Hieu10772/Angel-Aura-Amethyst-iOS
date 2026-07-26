#import "HapticManager.h"

@implementation HapticManager

+ (HapticManager *)shared {
    static HapticManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)play:(HapticType)type {
    switch (type) {
        case HapticTypeLight:
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
            break;
        case HapticTypeMedium:
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
            break;
        case HapticTypeHeavy:
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
            break;
        case HapticTypeSoft:
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
            break;
        case HapticTypeRigid:
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid] impactOccurred];
            break;
        case HapticTypeError:
            [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
            break;
        case HapticTypeSuccess:
            [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
            break;
        case HapticTypeWarning:
            [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeWarning];
            break;
        case HapticTypeSelection:
            [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
            break;
    }
}

@end
