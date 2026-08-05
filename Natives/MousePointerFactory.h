#import <UIKit/UIKit.h>

// Generates the virtual mouse pointer images for the launcher's
// cursor personalization feature (control.mouse_pointer_style).
@interface MousePointerFactory : NSObject

// Available style keys: "default" (bundled asset), procedural shapes
// (arrow, crosshair, circle, dot, beam) and "custom" (user file picked
// from Settings, e.g. .cur/.ani/image).
+ (NSArray<NSString *> *)availableStyles;

// Returns the pointer image for the given style key ("default" returns
// the bundled MousePointer asset).
+ (UIImage *)imageForStyle:(NSString *)style;

// Returns the hotspot (in normalized box coordinates 0..1) of the style:
// where inside the 18x27 pointer box the actual cursor position sits.
// Arrow-style pointers use (0,0) (tip at top-left); centered shapes use
// (0.5,0.5).
+ (CGPoint)hotspotForStyle:(NSString *)style;

@end
