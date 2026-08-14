#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Quản lý các con trỏ chuột ảo trong thư mục Documents/cursors.
/// Mỗi con trỏ là một thư mục chứa ảnh (image.png hoặc image.gif)
/// và file hitbox.json lưu toạ độ hitbox (điểm "nóng" của con trỏ).
@interface CursorManager : NSObject

/// Đường dẫn thư mục gốc (Documents/cursors), tự tạo nếu chưa có.
+ (NSString *)cursorsDirectory;

/// Tên con trỏ mặc định ("default") - không thể xoá.
+ (NSString *)defaultCursorName;
+ (BOOL)isDefaultCursor:(NSString *)name;

/// Danh sách tên con trỏ đã cài đặt (luôn có "default" ở đầu).
+ (NSArray<NSString *> *)cursorNames;

/// Con trỏ đang được chọn (pref control.virtmouse_cursor).
+ (NSString *)currentCursorName;
+ (void)setCurrentCursorName:(NSString *)name;

/// Ảnh của con trỏ (hỗ trợ PNG/GIF); default dùng ảnh MousePointer có sẵn.
+ (UIImage *)imageForCursor:(NSString *)name;

/// Toạ độ hitbox (theo điểm ảnh của ảnh gốc).
+ (CGPoint)hitboxForCursor:(NSString *)name;
+ (void)setHitboxForCursor:(NSString *)name hitbox:(CGPoint)hitbox;

/// Xoá con trỏ (không thể xoá con trỏ mặc định).
+ (BOOL)deleteCursor:(NSString *)name;

/// Import con trỏ từ URL/file (png, jpg, gif, webp, cur, ani...).
/// Trả về tên con trỏ vừa tạo, nil nếu thất bại.
+ (nullable NSString *)importCursorFromURL:(NSURL *)url withName:(NSString *)name error:(NSError **)error;

/// Import con trỏ từ UIImage.
+ (nullable NSString *)importCursorFromImage:(UIImage *)image withName:(NSString *)name error:(NSError **)error;

/// Tính frame hiển thị con trỏ: mouseFrame.origin là vị trí chuột,
/// frame trả về đã offset theo hitbox và tỉ lệ control.mouse_scale.
+ (CGRect)displayFrameForMouseFrame:(CGRect)mouseFrame;

/// Ngược lại của displayFrameForMouseFrame.
+ (CGRect)mouseFrameForDisplayFrame:(CGRect)displayFrame;

#import "CursorType.h"

+ (NSString *)normalCursorName;
+ (NSString *)handCursorName;
+ (NSString *)ibeamCursorName;
+ (NSString *)resizeEWCursorName;
+ (NSString *)resizeNSCursorName;

+ (void)setNormalCursorName:(NSString *)name;
+ (void)setHandCursorName:(NSString *)name;
+ (void)setIBeamCursorName:(NSString *)name;
+ (void)setResizeEWCursorName:(NSString *)name;
+ (void)setResizeNSCursorName:(NSString *)name;

+ (void)setCursorType:(CursorType)type;

@end

NS_ASSUME_NONNULL_END
