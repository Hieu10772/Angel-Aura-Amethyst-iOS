#pragma once
#import <UIKit/UIKit.h>
#include "jni.h"
#include <GLFW/glfw3.h>

#define CLIPBOARD_COPY 2000
#define CLIPBOARD_PASTE 2001

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
