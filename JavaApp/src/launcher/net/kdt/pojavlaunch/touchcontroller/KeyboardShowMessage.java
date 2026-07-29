package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class KeyboardShowMessage extends ProxyMessage {
    public final boolean show;

    public KeyboardShowMessage(boolean show) {
        this.show = show;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.KEYBOARD_SHOW; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        buffer.put(show ? (byte) 1 : (byte) 0);
    }

    public static KeyboardShowMessage decode(ByteBuffer buffer) {
        boolean show = buffer.get() == 1;
        return new KeyboardShowMessage(show);
    }
}