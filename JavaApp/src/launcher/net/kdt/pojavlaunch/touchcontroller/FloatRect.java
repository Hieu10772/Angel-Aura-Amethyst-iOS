package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class FloatRect {
    public final float left;
    public final float top;
    public final float right;
    public final float bottom;

    public FloatRect(float left, float top, float right, float bottom) {
        this.left = left;
        this.top = top;
        this.right = right;
        this.bottom = bottom;
    }

    public float width() { return right - left; }
    public float height() { return bottom - top; }

    public void encode(ByteBuffer buffer) {
        buffer.putFloat(left);
        buffer.putFloat(top);
        buffer.putFloat(right);
        buffer.putFloat(bottom);
    }

    public static FloatRect decode(ByteBuffer buffer) {
        float left = buffer.getFloat();
        float top = buffer.getFloat();
        float right = buffer.getFloat();
        float bottom = buffer.getFloat();
        return new FloatRect(left, top, right, bottom);
    }

    @Override
    public String toString() {
        return "FloatRect{[" + left + "," + top + "] - [" + right + "," + bottom + "]}";
    }
}