package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class ClearPointerMessage extends ProxyMessage {
    public static final ClearPointerMessage INSTANCE = new ClearPointerMessage();

    private ClearPointerMessage() {}

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.CLEAR_POINTER; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
    }

    public static ClearPointerMessage decode(ByteBuffer buffer) {
        return INSTANCE;
    }
}