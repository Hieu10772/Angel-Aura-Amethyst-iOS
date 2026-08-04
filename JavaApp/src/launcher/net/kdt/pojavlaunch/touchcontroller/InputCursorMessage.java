package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Cursor rect message (type 9). Wire format: [hasData:1][left:4][top:4]
 * [width:4][height:4], matching the current TouchController protocol.
 */
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
        if (cursorRect != null) {
            buffer.put((byte) 1);
            buffer.putFloat(cursorRect.left);
            buffer.putFloat(cursorRect.top);
            buffer.putFloat(cursorRect.width());
            buffer.putFloat(cursorRect.height());
        } else {
            buffer.put((byte) 0);
        }
    }

    public static InputCursorMessage decode(ByteBuffer buffer) {
        boolean hasData = buffer.get() != 0;
        if (!hasData) return new InputCursorMessage(null);
        float left = buffer.getFloat();
        float top = buffer.getFloat();
        float width = buffer.getFloat();
        float height = buffer.getFloat();
        return new InputCursorMessage(new FloatRect(left, top, left + width, top + height));
    }
}