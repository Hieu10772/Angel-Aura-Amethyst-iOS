#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Màn hình chọn toạ độ hitbox (điểm "nóng") cho một con trỏ chuột.
/// Người dùng kéo/chạm vào ảnh để đặt điểm hitbox, kết quả được lưu
/// vào file hitbox.json trong thư mục của con trỏ.
@interface CursorHitboxEditorViewController : UIViewController

@property (nonatomic, strong) NSString *cursorName;

@end

NS_ASSUME_NONNULL_END
