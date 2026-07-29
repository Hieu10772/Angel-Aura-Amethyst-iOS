package net.kdt.pojavlaunch.touchcontroller;

/**
 * Platform capabilities matching TouchController's PlatformCapability enum.
 */
public enum PlatformCapability {
    TOUCH("touch"),
    VIBRATION("vibration"),
    TEXT_STATUS("text_status"),
    KEYBOARD_SHOW("keyboard_show");

    public final String id;
    
    PlatformCapability(String id) {
        this.id = id;
    }
}