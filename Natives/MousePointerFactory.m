#import "MousePointerFactory.h"
#import "CursorFileDecoder.h"
#import "LauncherPreferences.h"
#include "utils.h"

// All procedural styles are drawn on a 36x54 canvas (2:3 aspect), which
// matches the 18x27 point frame the pointer view is rendered at, so the
// image is always exactly aspect-fit and hotspots map 1:1 to the box.
static const CGFloat kCanvasWidth = 36.0;
static const CGFloat kCanvasHeight = 54.0;
static const CGFloat kCanvasScale = 3.0;
static const CGFloat kPointerBoxWidth = 18.0;
static const CGFloat kPointerBoxHeight = 27.0;

// Cache for the custom cursor file (decoding is somewhat expensive and
// both imageForStyle: and hotspotForStyle: need the result).
static NSString *cachedCustomPath;
static UIImage *cachedCustomImage;
static CGPoint cachedCustomHotspot = {0.5, 0.5};

@implementation MousePointerFactory

+ (NSArray<NSString *> *)availableStyles {
    return @[ @"default", @"arrow", @"crosshair", @"circle", @"dot", @"beam", @"custom" ];
}

+ (CGPoint)hotspotForStyle:(NSString *)style {
    if ([style isEqualToString:@"custom"]) {
        [self customPointerImage];
        return cachedCustomHotspot;
    }
    if ([style isEqualToString:@"arrow"]) {
        return CGPointMake(0, 0);
    }
    return CGPointMake(0.5, 0.5);
}

+ (UIImage *)imageForStyle:(NSString *)style {
    if (style.length == 0) {
        style = @"default";
    }
    if ([style isEqualToString:@"custom"]) {
        return [self customPointerImage] ?: [UIImage imageNamed:@"MousePointer"];
    }
    if ([style isEqualToString:@"default"]) {
        return [UIImage imageNamed:@"MousePointer"];
    }

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = kCanvasScale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
        initWithSize:CGSizeMake(kCanvasWidth, kCanvasHeight) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        CGContextRef context = rendererContext.CGContext;
        CGContextClearRect(context, CGRectMake(0, 0, kCanvasWidth, kCanvasHeight));

        if ([style isEqualToString:@"arrow"]) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(1, 1)];
            [path addLineToPoint:CGPointMake(25, 13)];
            [path addLineToPoint:CGPointMake(16, 14)];
            [path addLineToPoint:CGPointMake(14, 25)];
            [path addLineToPoint:CGPointMake(9.5, 23)];
            [path addLineToPoint:CGPointMake(12, 12)];
            [path addLineToPoint:CGPointMake(1, 9)];
            [path closePath];
            [self fillPath:path inContext:context withOutlineWidth:2];
        } else if ([style isEqualToString:@"crosshair"]) {
            UIBezierPath *horizontal = [UIBezierPath bezierPathWithRect:CGRectMake(6, 24, 24, 6)];
            UIBezierPath *vertical = [UIBezierPath bezierPathWithRect:CGRectMake(15, 15, 6, 24)];
            UIBezierPath *cross = [UIBezierPath bezierPath];
            [cross appendPath:horizontal];
            [cross appendPath:vertical];
            [self fillPath:cross inContext:context withOutlineWidth:2];
            UIBezierPath *centerDot = [UIBezierPath bezierPathWithArcCenter:CGPointMake(18, 27)
                                                                     radius:2.2
                                                                 startAngle:0
                                                                   endAngle:2 * M_PI
                                                                  clockwise:YES];
            [[UIColor blackColor] setFill];
            [centerDot fill];
        } else if ([style isEqualToString:@"circle"]) {
            UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(9, 18, 18, 18)];
            [self fillPath:ring inContext:context withOutlineWidth:3];
        } else if ([style isEqualToString:@"dot"]) {
            UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(11, 20, 14, 14)];
            [self fillPath:dot inContext:context withOutlineWidth:2];
        } else if ([style isEqualToString:@"beam"]) {
            UIBezierPath *beam = [UIBezierPath bezierPath];
            [beam appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(15, 9, 6, 36)]];
            [beam appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(10, 9, 16, 4)]];
            [beam appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(10, 41, 16, 4)]];
            [self fillPath:beam inContext:context withOutlineWidth:2];
        } else {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(1, 1)];
            [path addLineToPoint:CGPointMake(25, 13)];
            [path addLineToPoint:CGPointMake(16, 14)];
            [path addLineToPoint:CGPointMake(14, 25)];
            [path addLineToPoint:CGPointMake(9.5, 23)];
            [path addLineToPoint:CGPointMake(12, 12)];
            [path addLineToPoint:CGPointMake(1, 9)];
            [path closePath];
            [self fillPath:path inContext:context withOutlineWidth:2];
        }
    }];
}

+ (void)fillPath:(UIBezierPath *)path
       inContext:(CGContextRef)context
withOutlineWidth:(CGFloat)width {
    path.lineWidth = width;
    path.lineJoinStyle = kCGLineJoinRound;
    path.lineCapStyle = kCGLineCapRound;
    [[UIColor blackColor] setStroke];
    [path stroke];
    [[UIColor whiteColor] setFill];
    [path fill];
}

// Loads the user's custom pointer file (pref control.mouse_pointer_file)
// and returns it, or nil if unset/undecodable. The cached hotspot is
// already converted to pointer-box coordinates (18x27, AspectFit).
+ (UIImage *)customPointerImage {
    id pathObj = getPrefObject(@"control.mouse_pointer_file");
    NSString *path = ([pathObj isKindOfClass:[NSString class]] && [(NSString *)pathObj length] > 0) ? pathObj : nil;
    if (!path) {
        cachedCustomPath = nil;
        cachedCustomImage = nil;
        cachedCustomHotspot = CGPointMake(0.5, 0.5);
        return nil;
    }
    if (cachedCustomPath && [cachedCustomPath isEqualToString:path]) {
        return cachedCustomImage;
    }

    CGPoint imageHotspot = CGPointMake(0.5, 0.5);
    UIImage *img = [CursorFileDecoder decodeFileAtPath:path hotspot:&imageHotspot];
    if (!img) {
        cachedCustomPath = nil;
        cachedCustomImage = nil;
        cachedCustomHotspot = CGPointMake(0.5, 0.5);
        return nil;
    }

    // Map image-normalized hotspot to AspectFit pointer-box coordinates
    CGFloat scale = MIN(kPointerBoxWidth / img.size.width, kPointerBoxHeight / img.size.height);
    CGFloat drawnWidth = img.size.width * scale;
    CGFloat drawnHeight = img.size.height * scale;
    imageHotspot.x = clamp(imageHotspot.x, 0, 1);
    imageHotspot.y = clamp(imageHotspot.y, 0, 1);
    CGPoint boxHotspot = CGPointMake(
        0.5 + (imageHotspot.x - 0.5) * (drawnWidth / kPointerBoxWidth),
        0.5 + (imageHotspot.y - 0.5) * (drawnHeight / kPointerBoxHeight));
    boxHotspot.x = clamp(boxHotspot.x, 0, 1);
    boxHotspot.y = clamp(boxHotspot.y, 0, 1);

    cachedCustomPath = path;
    cachedCustomImage = img;
    cachedCustomHotspot = boxHotspot;
    return img;
}

@end
