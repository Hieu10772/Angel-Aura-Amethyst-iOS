package net.kdt.pojavlaunch.touchcontroller;

/**
 * iOS keyboard show/hide handler.
 * On iOS, we use native JNI to show/hide the soft keyboard.
 */
public class IosKeyboardShowHandler implements LauncherProxyClient.KeyboardShowHandler {
    private static final String TAG = "IosKeyboardShowHandler";
    private static volatile IosKeyboardShowHandler instance;

    // JNI natives live in the main executable (System.load'ed at startup,
    // see UIKit.java); no separate library to load here.

    private IosKeyboardShowHandler() {}

    public static IosKeyboardShowHandler getInstance() {
        if (instance == null) {
            synchronized (IosKeyboardShowHandler.class) {
                if (instance == null) {
                    instance = new IosKeyboardShowHandler();
                }
            }
        }
        return instance;
    }

    @Override
    public void showKeyboard() {
        System.out.println(TAG + ": Show keyboard requested");
        nativeShowKeyboard();
    }

    @Override
    public void hideKeyboard() {
        System.out.println(TAG + ": Hide keyboard requested");
        nativeHideKeyboard();
    }

    private static native void nativeShowKeyboard();
    private static native void nativeHideKeyboard();
}