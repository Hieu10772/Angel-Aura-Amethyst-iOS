package net.kdt.pojavlaunch.touchcontroller;

/**
 * iOS Vibration handler using UIImpactFeedbackGenerator
 */
public class IosVibrationHandler implements LauncherProxyClient.VibrationHandler {
    // JNI natives live in the main executable (System.load'ed at startup,
    // see UIKit.java); no separate library to load here.

    public enum VibrateType {
        LIGHT(0),      // UIImpactFeedbackStyleLight
        MEDIUM(1),     // UIImpactFeedbackStyleMedium
        HEAVY(2),      // UIImpactFeedbackStyleHeavy
        SELECTION(3);  // UISelectionFeedbackGenerator

        public final int value;
        VibrateType(int value) { this.value = value; }
    }

    private native void nativeVibrate(int type);

    @Override
    public void vibrate(VibrateMessage.Kind kind) {
        VibrateType type;
        if (kind == VibrateMessage.Kind.LIGHT) {
            type = VibrateType.LIGHT;
        } else if (kind == VibrateMessage.Kind.MEDIUM) {
            type = VibrateType.MEDIUM;
        } else if (kind == VibrateMessage.Kind.HEAVY) {
            type = VibrateType.HEAVY;
        } else {
            type = VibrateType.SELECTION;
        }
        nativeVibrate(type.value);
    }
}