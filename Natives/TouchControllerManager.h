/*
 * TouchControllerManager - iOS native bridge for TouchController mod
 * Called from JavaLauncher.m before JVM launch to initialize the transport
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TouchControllerManager : NSObject

+ (void)initializeWithWidth:(int)width height:(int)height;

@end