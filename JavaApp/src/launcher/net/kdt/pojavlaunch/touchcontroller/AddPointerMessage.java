package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class AddPointerMessage extends ProxyMessage {
    public final int index;
    public final float x;
    public final float y;

    public AddPointerMessage(int index, float x, float y) {
        this.index = index;
        this.x = x;
        this.y = y;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.ADD_POINTER; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        buffer.putInt(index);
        buffer.putFloat(x);
        buffer.putFloat(y);
    }

    public static AddPointerMessage decode(ByteBuffer buffer) {
        int index = buffer.getInt();
        float x = buffer.getFloat();
        float y = buffer.getFloat();
        return new AddPointerMessage(index, x, y);
    }
}