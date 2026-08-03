package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Input area message (type 11). Wire format: [hasData:1][left:4][top:4]
 * [width:4][height:4], matching the current TouchController protocol.
 */
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
        if (inputAreaRect != null) {
            buffer.put((byte) 1);
            buffer.putFloat(inputAreaRect.left);
            buffer.putFloat(inputAreaRect.top);
            buffer.putFloat(inputAreaRect.width());
            buffer.putFloat(inputAreaRect.height());
        } else {
            buffer.put((byte) 0);
        }
    }

    public static InputAreaMessage decode(ByteBuffer buffer) {
        boolean hasData = buffer.get() != 0;
        if (!hasData) return new InputAreaMessage(null);
        float left = buffer.getFloat();
        float top = buffer.getFloat();
        float width = buffer.getFloat();
        float height = buffer.getFloat();
        return new InputAreaMessage(new FloatRect(left, top, left + width, top + height));
    }
}