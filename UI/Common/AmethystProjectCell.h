#import <UIKit/UIKit.h>

@interface AmethystProjectCell : UITableViewCell
@property (nonatomic) UIImageView *projectIcon;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle iconURL:(NSString *)iconURL placeholder:(NSString *)symbolName;
@end
