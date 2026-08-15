#pragma once

#import <UIKit/UIKit.h>
#include "jni.h"

#define CLIPBOARD_COPY 2000
#define CLIPBOARD_PASTE 2001

// GLFW standard cursor shape constants.
// Kept here because the native Amethyst target does not include GLFW's
// glfw3.h header.
#define GLFW_ARROW_CURSOR        0x36001
#define GLFW_IBEAM_CURSOR        0x36002
#define GLFW_CROSSHAIR_CURSOR    0x36003
#define GLFW_POINTING_HAND_CURSOR 0x36004
#define GLFW_RESIZE_EW_CURSOR    0x36005
#define GLFW_RESIZE_NS_CURSOR    0x36006
#define GLFW_RESIZE_NWSE_CURSOR  0x36007
#define GLFW_RESIZE_NESW_CURSOR  0x36008
#define GLFW_RESIZE_ALL_CURSOR   0x36009
#define GLFW_NOT_ALLOWED_CURSOR  0x3600A

extern int currentGLFWCursorShape;

void CallbackBridge_nativeSetCursorShape(int shape);

UIViewController* tmpRootVC;

void showDialog(NSString* title, NSString* message);
jstring UIKit_accessClipboard(JNIEnv* env, jint action, jstring copySrc);
void UIKit_launchMinecraftSurfaceVC(UIWindow *window, NSDictionary *metadata);
void UIKit_launchJarFile(UIWindow *window, NSString *jarPath);
void UIKit_launchJarFileWithArgs(UIWindow *window, NSString *jarPath, NSArray<NSString *> *args, int minJavaVersion);
void UIKit_returnToSplitView();
void launchInitialViewController(UIWindow *window);

void AWTInputBridge_sendKey(int keycode);
