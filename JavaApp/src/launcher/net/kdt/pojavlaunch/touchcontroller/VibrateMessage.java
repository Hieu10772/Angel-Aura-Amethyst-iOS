package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Vibration message. Wire kinds follow the current TouchController protocol:
 * 0 = BLOCK_BROKEN, anything else = UNKNOWN.
 */
public final class VibrateMessage extends ProxyMessage {
    public enum Kind {
        LIGHT(0), MEDIUM(1), HEAVY(2), SELECTION(3);

        public final int id;
        Kind(int id) { this.id = id; }
        public static Kind fromInt(int id) {
            for (Kind k : values()) if (k.id == id) return k;
            return LIGHT;
        }
    }

    public final Kind kind;

    public VibrateMessage(Kind kind) {
        this.kind = kind;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.VIBRATE; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        buffer.putInt(kind.id);
    }

    public static VibrateMessage decode(ByteBuffer buffer) {
        int kind = buffer.getInt();
        // Mod only sends 0 (BLOCK_BROKEN) or -1 (UNKNOWN). Map to haptic styles.
        Kind mapped = kind == 0 ? Kind.LIGHT : Kind.SELECTION;
        return new VibrateMessage(mapped);
    }
}