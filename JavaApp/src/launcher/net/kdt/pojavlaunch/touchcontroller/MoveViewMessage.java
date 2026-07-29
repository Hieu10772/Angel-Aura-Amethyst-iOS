package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class MoveViewMessage extends ProxyMessage {
    public final boolean screenBased;
    public final float deltaPitch;
    public final float deltaYaw;

    public MoveViewMessage(boolean screenBased, float deltaPitch, float deltaYaw) {
        this.screenBased = screenBased;
        this.deltaPitch = deltaPitch;
        this.deltaYaw = deltaYaw;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.MOVE_VIEW; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        buffer.put(screenBased ? (byte) 1 : (byte) 0);
        buffer.putFloat(deltaPitch);
        buffer.putFloat(deltaYaw);
    }

    public static MoveViewMessage decode(ByteBuffer buffer) {
        boolean screenBased = buffer.get() == 1;
        float deltaPitch = buffer.getFloat();
        float deltaYaw = buffer.getFloat();
        return new MoveViewMessage(screenBased, deltaPitch, deltaYaw);
    }
}