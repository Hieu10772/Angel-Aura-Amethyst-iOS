package net.kdt.pojavlaunch.touchcontroller;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Main manager for TouchController integration in the Amethyst iOS launcher.
 * Handles communication between the launcher (touch input) and the mod (game).
 *
 * The touch entry points (onTouchDown/Move/Up/Cancel/ViewMove) are static
 * because they are invoked from native code (touchcontroller_jni_bridge.c)
 * via GetStaticMethodID.
 */
public class TouchControllerManager {
    private static final String TAG = "TouchControllerManager";

    private static volatile TouchControllerManager instance;
    private LauncherProxyClient proxyClient;
    private IosSocketTransport transport;
    private boolean initialized = false;
    private int gameWidth = 0;
    private int gameHeight = 0;

    // Touch tracking
    private final ConcurrentHashMap<Integer, TouchPoint> activeTouches = new ConcurrentHashMap<>();
    private int nextPointerIndex = 1;

    private TouchControllerManager() {}

    public static TouchControllerManager getInstance() {
        if (instance == null) {
            synchronized (TouchControllerManager.class) {
                if (instance == null) {
                    instance = new TouchControllerManager();
                }
            }
        }
        return instance;
    }

    /**
     * Initialize TouchController before launching Minecraft.
     * Must be called before the game main class is loaded.
     */
    public void initialize(int width, int height) {
        if (initialized) {
            System.out.println(TAG + ": Already initialized");
            return;
        }

        this.gameWidth = width;
        this.gameHeight = height;

        try {
            // Create iOS transport (JNI to native ring buffer)
            transport = IosSocketTransport.create();

            // Create proxy client with capabilities understood by the mod
            proxyClient = new LauncherProxyClient(transport, new HashSet<>(Arrays.asList(
                LauncherProxyClient.PlatformCapability.TEXT_STATUS,
                LauncherProxyClient.PlatformCapability.KEYBOARD_SHOW
            )));

            // Set vibration handler (iOS haptics)
            proxyClient.setVibrationHandler(new IosVibrationHandler());

            // Set input handler (keyboard show/hide)
            proxyClient.setInputHandler(new IosInputHandler());

            // Set keyboard show handler
            proxyClient.setKeyboardShowHandler(IosKeyboardShowHandler.getInstance());

            // Start the proxy client (starts message processing thread)
            proxyClient.run();

            initialized = true;
            System.out.println(TAG + ": TouchController initialized, size=" + width + "x" + height);

        } catch (Exception e) {
            System.err.println(TAG + ": Failed to initialize TouchController: " + e.getMessage());
            e.printStackTrace();
            // Don't crash - touch controller is optional
        }
    }

    /**
     * Called when a touch begins.
     * @param x Normalized X coordinate [0, 1] relative to game view
     * @param y Normalized Y coordinate [0, 1] relative to game view
     * @return Pointer index assigned to this touch
     */
    public static int onTouchDown(float x, float y) {
        TouchControllerManager manager = getInstance();
        if (!manager.initialized || manager.proxyClient == null) return -1;

        int index = manager.nextPointerIndex++;
        manager.activeTouches.put(index, new TouchPoint(x, y));
        manager.proxyClient.addPointer(index, x, y);
        return index;
    }

    /**
     * Called when a touch moves.
     */
    public static void onTouchMove(int index, float x, float y) {
        TouchControllerManager manager = getInstance();
        if (!manager.initialized || manager.proxyClient == null) return;

        TouchPoint point = manager.activeTouches.get(index);
        if (point != null) {
            point.x = x;
            point.y = y;
            manager.proxyClient.addPointer(index, x, y);
        }
    }

    /**
     * Called when a touch ends.
     */
    public static void onTouchUp(int index) {
        TouchControllerManager manager = getInstance();
        if (!manager.initialized || manager.proxyClient == null) return;

        manager.activeTouches.remove(index);
        manager.proxyClient.removePointer(index);
    }

    /**
     * Called when all touches are cancelled.
     */
    public static void onTouchCancel() {
        TouchControllerManager manager = getInstance();
        if (!manager.initialized || manager.proxyClient == null) return;

        manager.activeTouches.clear();
        manager.proxyClient.clearPointer();
    }

    /**
     * Handle view movement (drag on screen for camera rotation).
     */
    public static void onViewMove(float deltaPitch, float deltaYaw) {
        TouchControllerManager manager = getInstance();
        if (!manager.initialized || manager.proxyClient == null) return;

        manager.proxyClient.moveView(true, deltaPitch, deltaYaw);
    }

    /**
     * Update game dimensions (called when surface size changes).
     */
    public void updateGameSize(int width, int height) {
        this.gameWidth = width;
        this.gameHeight = height;
    }

    public boolean isInitialized() {
        return initialized;
    }

    public int getGameWidth() {
        return gameWidth;
    }

    public int getGameHeight() {
        return gameHeight;
    }

    public void shutdown() {
        if (proxyClient != null) {
            proxyClient.close();
            proxyClient = null;
        }
        if (transport != null) {
            transport.close();
            transport = null;
        }
        initialized = false;
        System.out.println(TAG + ": Shutdown complete");
    }

    private static class TouchPoint {
        float x, y;
        TouchPoint(float x, float y) {
            this.x = x;
            this.y = y;
        }
    }
}