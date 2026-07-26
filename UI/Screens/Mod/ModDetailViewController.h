#import <UIKit/UIKit.h>

@class MainCoordinator;

@interface ModDetailViewController : UIViewController
@property (nonatomic, weak) MainCoordinator *coordinator;
- (instancetype)initWithMod:(NSDictionary *)mod;
@end