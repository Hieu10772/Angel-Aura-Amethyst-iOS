#import <UIKit/UIKit.h>

// Decodes Windows cursor files (.cur), animated cursor first frames (.ani)
// and any image format UIKit can open (png, jpg, gif, bmp, tiff, webp...).
// iOS ImageIO does not support ICO/CUR/ANI natively, so .cur/.ani are
// parsed manually (ICO header + DIB/PNG payload, RIFF ACON frame list).
@interface CursorFileDecoder : NSObject

// Returns the decoded image, or nil if the file is not decodable.
// If hotspot is non-NULL it receives the cursor hotspot in normalized
// image coordinates (0..1), or the image center for plain images.
+ (UIImage *)decodeFileAtPath:(NSString *)path hotspot:(CGPoint *)hotspot;

@end
