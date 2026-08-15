package org.lwjgl.glfw;

public final class CallbackBridge {

    private CallbackBridge() {
    }

    public static native void nativeSetCursorShape(long window, int shape);
}
