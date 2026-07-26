#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HapticType) {
    HapticTypeLight,
    HapticTypeMedium,
    HapticTypeHeavy,
    HapticTypeSoft,
    HapticTypeRigid,
    HapticTypeError,
    HapticTypeSuccess,
    HapticTypeWarning,
    HapticTypeSelection
};

@interface HapticManager : NSObject

@property (class, readonly) HapticManager *shared;

- (void)play:(HapticType)type;

@end
