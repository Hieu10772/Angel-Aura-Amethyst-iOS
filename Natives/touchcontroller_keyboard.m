/*
 * TouchController iOS Keyboard Implementation
 * Shows/hides the iOS soft keyboard
 */

#import <UIKit/UIKit.h>

void touchcontroller_showKeyboard() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            // Find the game view (SurfaceViewController's view) and make it first responder
            UIView* rootView = window.rootViewController.view;
            if ([rootView respondsToSelector:@selector(becomeFirstResponder)]) {
                [rootView becomeFirstResponder];
            }
        }
    });
}

void touchcontroller_hideKeyboard() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            [window endEditing:YES];
        }
    });
}