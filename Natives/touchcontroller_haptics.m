/*
 * TouchController iOS Launcher Haptics & Keyboard Bridge
 * Objective-C implementation for iOS native features
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "touchcontroller_launcher.h"

// Haptic feedback generators
static UIImpactFeedbackGenerator* lightGenerator = nil;
static UIImpactFeedbackGenerator* mediumGenerator = nil;
static UIImpactFeedbackGenerator* heavyGenerator = nil;
static UISelectionFeedbackGenerator* selectionGenerator = nil;

static void prepareGenerators() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lightGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        mediumGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        heavyGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
        selectionGenerator = [[UISelectionFeedbackGenerator alloc] init];
        
        [lightGenerator prepare];
        [mediumGenerator prepare];
        [heavyGenerator prepare];
        [selectionGenerator prepare];
    });
}

void touchcontroller_vibrate(int type) {
    prepareGenerators();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (type) {
            case 0: // LIGHT
                [lightGenerator impactOccurred];
                [lightGenerator prepare];
                break;
            case 1: // MEDIUM
                [mediumGenerator impactOccurred];
                [mediumGenerator prepare];
                break;
            case 2: // HEAVY
                [heavyGenerator impactOccurred];
                [heavyGenerator prepare];
                break;
            case 3: // SELECTION
                [selectionGenerator selectionChanged];
                [selectionGenerator prepare];
                break;
        }
    });
}

void touchcontroller_showKeyboard() {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Find the game view and make it first responder
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            UIView* rootView = window.rootViewController.view;
            // The game surface view should become first responder
            // This will trigger the system keyboard to appear
            [rootView becomeFirstResponder];
        }
    });
}

void touchcontroller_hideKeyboard() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            [window.endEditing(true)];
        }
    });
}