package net.kdt.pojavlaunch.touchcontroller;

public enum ProxyMessageType {
    INITIALIZE(0),
    CAPABILITY(1),
    ADD_POINTER(2),
    REMOVE_POINTER(3),
    CLEAR_POINTER(4),
    MOVE_VIEW(5),
    INPUT_STATUS(6),
    INPUT_CURSOR(7),
    INPUT_AREA(8),
    KEYBOARD_SHOW(9),
    VIBRATE(10);

    public final int id;
    ProxyMessageType(int id) { this.id = id; }

    public static ProxyMessageType fromId(int id) {
        for (ProxyMessageType t : values()) {
            if (t.id == id) return t;
        }
        return null;
    }
}