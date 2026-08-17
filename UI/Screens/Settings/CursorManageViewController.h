#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CursorManageType) {
    CursorManageTypeNormal = 0,
    CursorManageTypeHand,
    CursorManageTypeIBeam,
    CursorManageTypeResizeEW,
    CursorManageTypeResizeNS
};

@interface CursorManageViewController : UIViewController

@property (nonatomic, assign) CursorManageType cursorType;

@end

NS_ASSUME_NONNULL_END
