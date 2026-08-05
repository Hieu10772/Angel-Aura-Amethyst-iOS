#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InstallerProgressViewController : UIViewController

@property (nonatomic, copy) NSString *jarPath;
@property (nonatomic, copy) NSArray<NSString *> *jvmArgs;
@property (nonatomic, copy) NSString *installTitle;
@property (nonatomic, copy) void (^completion)(BOOL success, BOOL cancelled, int exitCode);

+ (void)presentInstallerFrom:(UIViewController *)hostVC
                     jarPath:(NSString *)jarPath
                       title:(NSString *)title
                     jvmArgs:(NSArray<NSString *> *)args
                  completion:(void (^)(BOOL success, BOOL cancelled, int exitCode))completion;

@end

NS_ASSUME_NONNULL_END
