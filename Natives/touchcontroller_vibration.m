/*
 * TouchController iOS Vibration Implementation
 * Uses UIImpactFeedbackGenerator for haptic feedback
 */

#import <UIKit/UIKit.h>

void touchcontroller_vibrate(int type) {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (type) {
            case 0: { // LIGHT
                static UIImpactFeedbackGenerator* generator = nil;
                if (!generator) {
                    generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                    [generator prepare];
                }
                [generator impactOccurred];
                break;
            }
            case 1: { // MEDIUM
                static UIImpactFeedbackGenerator* generator = nil;
                if (!generator) {
                    generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                    [generator prepare];
                }
                [generator impactOccurred];
                break;
            }
            case 2: { // HEAVY
                static UIImpactFeedbackGenerator* generator = nil;
                if (!generator) {
                    generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                    [generator prepare];
                }
                [generator impactOccurred];
                break;
            }
            case 3: { // SELECTION
                static UISelectionFeedbackGenerator* generator = nil;
                if (!generator) {
                    generator = [[UISelectionFeedbackGenerator alloc] init];
                    [generator prepare];
                }
                [generator selectionChanged];
                break;
            }
            default: {
                static UIImpactFeedbackGenerator* generator = nil;
                if (!generator) {
                    generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                    [generator prepare];
                }
                [generator impactOccurred];
                break;
            }
        }
    });
}