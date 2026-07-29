package net.kdt.pojavlaunch.touchcontroller;

import net.kdt.pojavlaunch.uikit.UIKit;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Main manager for TouchController integration in the Amethyst iOS launcher.
 * Handles communication between the launcher (touch input) and the mod (game).
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
     * Must be called before JLI_Launch.
     */
    public void initialize(int width, int height) {
        if (initialized) {
            System.out.println(TAG + ": Already initialized");
            return;
        }

        this.gameWidth = width;
        this.gameHeight = height;
        
        String socketName = "Amethyst-iOS";
        
        // Set environment variable for the mod to find the socket
        System.setProperty("TOUCH_CONTROLLER_PROXY_SOCKET", socketName);
        
        try {
            // Create iOS transport (JNI to native ring buffer)
            transport = IosSocketTransport.create(socketName);
            
            // Create proxy client with capabilities
            proxyClient = new LauncherProxyClient(transport, new HashSet<>(Arrays.asList(
                LauncherProxyClient.PlatformCapability.TOUCH,
                LauncherProxyClient.PlatformCapability.VIBRATION,
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
            System.out.println(TAG + ": TouchController initialized with socket: " + socketName);
            
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
    public int onTouchDown(float x, float y) {
        if (!initialized || proxyClient == null) return -1;
        
        int index = nextPointerIndex++;
        activeTouches.put(index, new TouchPoint(x, y));
        proxyClient.addPointer(index, x, y);
        System.out.println(TAG + ": Touch down index=" + index + " x=" + x + " y=" + y);
        return index;
    }

    /**
     * Called when a touch moves.
     */
    public void onTouchMove(int index, float x, float y) {
        if (!initialized || proxyClient == null) return;
        
        TouchPoint point = activeTouches.get(index);
        if (point != null) {
            point.x = x;
            point.y = y;
            proxyClient.addPointer(index, x, y);
        }
    }

    /**
     * Called when a touch ends.
     */
    public void onTouchUp(int index) {
        if (!initialized || proxyClient == null) return;
        
        activeTouches.remove(index);
        proxyClient.removePointer(index);
        System.out.println(TAG + ": Touch up index=" + index);
    }

    /**
     * Called when all touches are cancelled.
     */
    public void onTouchCancel() {
        if (!initialized || proxyClient == null) return;
        
        activeTouches.clear();
        proxyClient.clearPointer();
        System.out.println(TAG + ": Touch cancel - all pointers cleared");
    }

    /**
     * Handle view movement (drag on screen for camera rotation).
     */
    public void onViewMove(float deltaPitch, float deltaYaw) {
        if (!initialized || proxyClient == null) return;
        
        proxyClient.moveView(true, deltaPitch, deltaYaw);
    }

    /**
     * Update game dimensions (called when surface size changes).
     */
    public void updateGameSize(int width, int height) {
        this.gameWidth = width;
        this.gameHeight = height;
        // Could send InputAreaMessage to mod if needed
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