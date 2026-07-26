#import <UIKit/UIKit.h>

@interface ColorPickerViewController : UIViewController

@property (nonatomic, copy) void (^onColorSelected)(UIColor *color);
@property (nonatomic, strong) UIColor *initialColor;

@end
