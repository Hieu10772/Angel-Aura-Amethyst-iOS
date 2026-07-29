package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

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
        Kind kind = Kind.fromInt(buffer.getInt());
        return new VibrateMessage(kind);
    }
}