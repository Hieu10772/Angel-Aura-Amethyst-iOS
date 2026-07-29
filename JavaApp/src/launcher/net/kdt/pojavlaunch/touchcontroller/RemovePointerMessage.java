package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class RemovePointerMessage extends ProxyMessage {
    public final int index;

    public RemovePointerMessage(int index) {
        this.index = index;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.REMOVE_POINTER; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        buffer.putInt(index);
    }

    public static RemovePointerMessage decode(ByteBuffer buffer) {
        int index = buffer.getInt();
        return new RemovePointerMessage(index);
    }
}