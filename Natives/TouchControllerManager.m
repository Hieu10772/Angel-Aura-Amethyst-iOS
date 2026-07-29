/*
 * TouchControllerManager - iOS native bridge for TouchController mod
 * Called from JavaLauncher.m before JVM launch to initialize the transport
 */

#import "TouchControllerManager.h"
#import "touchcontroller_launcher.h"

@implementation TouchControllerManager

+ (void)initializeWithWidth:(int)width height:(int)height {
    NSLog(@"[TouchController] Initializing with game size: %dx%d", width, height);
    
    // The actual JNI initialization happens in Java when the JVM starts
    // We just prepare the native transport here if needed
    // For now, the Java side (TouchControllerManager.initialize) handles the JNI setup
    
    // Store the dimensions for later use if needed
    // The Java side will also get these dimensions
}

@end