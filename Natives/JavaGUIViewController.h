#import <UIKit/UIKit.h>

@interface SurfaceView : UIView
- (void)displayLayer;
@end

@interface JavaGUIViewController : UIViewController
@property(nonatomic) NSString* filepath;
@property(nonatomic) NSArray<NSString *> *jvmArgs;
@property(nonatomic, readonly) int requiredJavaVersion;

+ (int)requiredJavaVersionForJar:(NSString *)filepath;
- (void)setHitEnterAfterWindowShown:(BOOL)hitEnter;
@end
