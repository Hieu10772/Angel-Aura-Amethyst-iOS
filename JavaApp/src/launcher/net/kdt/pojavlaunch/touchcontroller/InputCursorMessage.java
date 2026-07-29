package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class InputCursorMessage extends ProxyMessage {
    public final FloatRect cursorRect;

    public InputCursorMessage(FloatRect cursorRect) {
        this.cursorRect = cursorRect;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.INPUT_CURSOR; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        cursorRect.encode(buffer);
    }

    public static InputCursorMessage decode(ByteBuffer buffer) {
        FloatRect rect = FloatRect.decode(buffer);
        return new InputCursorMessage(rect);
    }
}