package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class InputStatusMessage extends ProxyMessage {
    public final TextInputState status;

    public InputStatusMessage(TextInputState status) {
        this.status = status;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.INPUT_STATUS; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        status.encode(buffer);
    }

    public static InputStatusMessage decode(ByteBuffer buffer) {
        TextInputState status = TextInputState.decode(buffer);
        return new InputStatusMessage(status);
    }
}