package net.kdt.pojavlaunch.touchcontroller;

/**
 * iOS input handler for text input status, cursor, and area updates.
 */
public class IosInputHandler implements LauncherProxyClient.InputHandler {
    private static final String TAG = "IosInputHandler";

    @Override
    public void updateState(TextInputState status) {
        System.out.println(TAG + ": Text input state changed: " + (status != null ? status.toString() : "null"));
        // Handle text input state changes (show/hide keyboard, update text, etc.)
        if (status != null && status.isActive()) {
            // Show keyboard
            IosKeyboardShowHandler.getInstance().showKeyboard();
        } else {
            // Hide keyboard
            IosKeyboardShowHandler.getInstance().hideKeyboard();
        }
    }

    @Override
    public void updateCursor(FloatRect cursorRect) {
        if (cursorRect != null) {
            System.out.println(TAG + ": Cursor rect updated: " + cursorRect.toString());
            // Update cursor position for IME
        }
    }

    @Override
    public void updateArea(FloatRect inputAreaRect) {
        if (inputAreaRect != null) {
            System.out.println(TAG + ": Input area rect updated: " + inputAreaRect.toString());
            // Update input area for IME
        }
    }
}