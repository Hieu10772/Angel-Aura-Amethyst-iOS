package net.kdt.pojavlaunch.touchcontroller;

/**
 * Message type IDs MUST match the current TouchController protocol
 * (top.fifthlight.touchcontroller.proxy.message.ProxyMessage).
 */
public enum ProxyMessageType {
    ADD_POINTER(1),
    REMOVE_POINTER(2),
    CLEAR_POINTER(3),
    VIBRATE(4),
    CAPABILITY(5),
    LARGE_MESSAGE(6),
    INPUT_STATUS(7),
    KEYBOARD_SHOW(8),
    INPUT_CURSOR(9),
    INITIALIZE(10),
    INPUT_AREA(11),
    MOVE_VIEW(12);

    public final int id;
    ProxyMessageType(int id) { this.id = id; }

    public static ProxyMessageType fromId(int id) {
        for (ProxyMessageType t : values()) {
            if (t.id == id) return t;
        }
        return null;
    }
}