#import <UIKit/UIKit.h>

@interface MrpackInstaller : NSObject

+ (void)installMrpackAtPath:(NSString *)dlPath title:(NSString *)title hostVC:(UIViewController *)hostVC removeOnCompletion:(BOOL)removeOnCompletion;

@end
