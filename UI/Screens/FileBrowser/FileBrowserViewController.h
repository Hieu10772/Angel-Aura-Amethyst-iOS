#import <UIKit/UIKit.h>

@interface FileBrowserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate>

@property (nonatomic) NSString *rootPath;

@end
