package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class InitializeMessage extends ProxyMessage {
    @Override
    public ProxyMessageType getType() { return ProxyMessageType.INITIALIZE; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
    }

    public static InitializeMessage decode(ByteBuffer buffer) {
        return new InitializeMessage();
    }
}