package org.lwjgl.glfw;

public final class CallbackBridge {

    public static final int CLIPBOARD_COPY = 2000;
    public static final int CLIPBOARD_PASTE = 2001;

    private CallbackBridge() {
    }

    public static native void nativeSetCursorShape(int shape);

    public static native void nativeSetGrabbing(boolean grab);

    public static native String nativeClipboard(int action, byte[] copy);
}
