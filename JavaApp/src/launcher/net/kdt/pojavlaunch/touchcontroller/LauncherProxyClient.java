package net.kdt.pojavlaunch.touchcontroller;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Main client for communicating with TouchController mod.
 * Handles the protocol: Capabilities -> Touch events (current TouchController wire protocol).
 */
public class LauncherProxyClient {
    private final MessageTransport transport;
    private final LauncherProxyMessageClient messageClient;
    private final Set<PlatformCapability> capabilities = ConcurrentHashMap.newKeySet();
    private final AtomicBoolean running = new AtomicBoolean(false);
    private Thread messageThread;

    // Handlers
    private VibrationHandler vibrationHandler;
    private InputHandler inputHandler;
    private KeyboardShowHandler keyboardShowHandler;

    public interface VibrationHandler {
        void vibrate(VibrateMessage.Kind kind);
    }

    public interface InputHandler {
        void updateState(TextInputState status);
        void updateCursor(FloatRect cursorRect);
        void updateArea(FloatRect inputAreaRect);
    }

    public interface KeyboardShowHandler {
        void showKeyboard();
        void hideKeyboard();
    }

    public enum PlatformCapability {
        TEXT_STATUS("text_status"),
        KEYBOARD_SHOW("keyboard_show"),
        TOUCH("touch"),
        VIBRATION("vibration");

        public final String id;
        PlatformCapability(String id) { this.id = id; }
    }

    public LauncherProxyClient(MessageTransport transport, Set<PlatformCapability> capabilities) {
        this.transport = transport;
        this.messageClient = new LauncherProxyMessageClient(transport);
        if (capabilities != null) {
            this.capabilities.addAll(capabilities);
        }
    }

    public void setVibrationHandler(VibrationHandler handler) { this.vibrationHandler = handler; }
    public void setInputHandler(InputHandler handler) { this.inputHandler = handler; }
    public void setKeyboardShowHandler(KeyboardShowHandler handler) { this.keyboardShowHandler = handler; }

    /**
     * Starts the message processing loop in a background thread.
     */
    public void run() {
        if (running.compareAndSet(false, true)) {
            messageClient.run();
            messageThread = new Thread(this::messageLoop, "TouchController-Proxy");
            messageThread.start();

            // Send initial capabilities after connection
            sendCapabilities();
        }
    }

    private void messageLoop() {
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        ByteArrayOutputStream largeBuffer = new ByteArrayOutputStream();
        while (running.get()) {
            try {
                if (messageClient.receive(buffer)) {
                    buffer.flip();
                    ProxyMessage msg = ProxyMessage.decode(buffer.getInt(), buffer);
                    if (msg != null) {
                        if (msg.getType() == ProxyMessageType.LARGE_MESSAGE) {
                            LargeMessage large = (LargeMessage) msg;
                            largeBuffer.write(large.payload);
                            if (large.end) {
                                byte[] assembled = largeBuffer.toByteArray();
                                largeBuffer.reset();
                                ByteBuffer inner = ByteBuffer.wrap(assembled);
                                if (inner.remaining() >= 4) {
                                    ProxyMessage innerMsg = ProxyMessage.decode(inner.getInt(), inner);
                                    if (innerMsg != null) {
                                        handleMessage(innerMsg);
                                    }
                                }
                            }
                        } else {
                            handleMessage(msg);
                        }
                    }
                    buffer.clear();
                } else {
                    // Connection closed or error
                    Thread.sleep(10);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                System.err.println("[TouchController] Error in message loop: " + e);
                e.printStackTrace();
            }
        }
    }

    private void handleMessage(ProxyMessage msg) {
        switch (msg.getType()) {
            case INITIALIZE:
                sendCapabilities();
                break;
            case VIBRATE:
                VibrateMessage vm = (VibrateMessage) msg;
                if (vibrationHandler != null) {
                    vibrationHandler.vibrate(vm.kind);
                }
                break;
            case INPUT_STATUS:
                InputStatusMessage ism = (InputStatusMessage) msg;
                if (inputHandler != null) {
                    inputHandler.updateState(ism.status);
                }
                break;
            case INPUT_CURSOR:
                InputCursorMessage icm = (InputCursorMessage) msg;
                if (inputHandler != null) {
                    inputHandler.updateCursor(icm.cursorRect);
                }
                break;
            case INPUT_AREA:
                InputAreaMessage iam = (InputAreaMessage) msg;
                if (inputHandler != null) {
                    inputHandler.updateArea(iam.inputAreaRect);
                }
                break;
            case KEYBOARD_SHOW:
                KeyboardShowMessage ksm = (KeyboardShowMessage) msg;
                if (keyboardShowHandler != null) {
                    if (ksm.show) keyboardShowHandler.showKeyboard();
                    else keyboardShowHandler.hideKeyboard();
                }
                break;
            default:
                // Ignore unknown messages
        }
    }

    private void sendCapabilities() {
        for (PlatformCapability cap : capabilities) {
            messageClient.send(new CapabilityMessage(cap.id, true));
        }
    }

    /**
     * Add or update a touch pointer.
     * @param index Pointer index (must be monotonically increasing from 1)
     * @param x Normalized X coordinate [0, 1] relative to game view
     * @param y Normalized Y coordinate [0, 1] relative to game view
     */
    public void addPointer(int index, float x, float y) {
        messageClient.send(new AddPointerMessage(index, x, y));
    }

    /**
     * Remove a touch pointer.
     * @param index Pointer index to remove
     */
    public void removePointer(int index) {
        messageClient.send(new RemovePointerMessage(index));
    }

    /**
     * Clear all touch pointers.
     */
    public void clearPointer() {
        messageClient.send(ClearPointerMessage.INSTANCE);
    }

    /**
     * Move the game view (camera rotation).
     * @param screenBased If true, deltas are screen-relative; if false, angle-based
     * @param deltaPitch Pitch delta (Y axis)
     * @param deltaYaw Yaw delta (X axis)
     */
    public void moveView(boolean screenBased, float deltaPitch, float deltaYaw) {
        messageClient.send(new MoveViewMessage(screenBased, deltaPitch, deltaYaw));
    }

    public void updateTextInputState(TextInputState newState) {
        if (!capabilities.contains(PlatformCapability.TEXT_STATUS)) return;
        messageClient.send(new InputStatusMessage(newState));
    }

    public void close() {
        running.set(false);
        if (messageThread != null) {
            messageThread.interrupt();
        }
        try {
            transport.close();
        } catch (Exception e) {
            // Ignore
        }
    }
}