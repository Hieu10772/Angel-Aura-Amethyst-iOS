package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class InputAreaMessage extends ProxyMessage {
    public final FloatRect inputAreaRect;

    public InputAreaMessage(FloatRect inputAreaRect) {
        this.inputAreaRect = inputAreaRect;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.INPUT_AREA; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        inputAreaRect.encode(buffer);
    }

    public static InputAreaMessage decode(ByteBuffer buffer) {
        FloatRect rect = FloatRect.decode(buffer);
        return new InputAreaMessage(rect);
    }
}