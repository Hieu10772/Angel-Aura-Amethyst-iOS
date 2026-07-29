package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class TextInputState {
    public final boolean active;
    public final String text;
    public final int selectionStart;
    public final int selectionEnd;
    public final int compositionStart;
    public final int compositionEnd;
    public final int cursorRectLeft;
    public final int cursorRectTop;
    public final int cursorRectRight;
    public final int cursorRectBottom;

    public TextInputState(boolean active, String text, int selectionStart, int selectionEnd,
                          int compositionStart, int compositionEnd,
                          int cursorRectLeft, int cursorRectTop, int cursorRectRight, int cursorRectBottom) {
        this.active = active;
        this.text = text;
        this.selectionStart = selectionStart;
        this.selectionEnd = selectionEnd;
        this.compositionStart = compositionStart;
        this.compositionEnd = compositionEnd;
        this.cursorRectLeft = cursorRectLeft;
        this.cursorRectTop = cursorRectTop;
        this.cursorRectRight = cursorRectRight;
        this.cursorRectBottom = cursorRectBottom;
    }

    public boolean isActive() { return active; }

    public void encode(ByteBuffer buffer) {
        buffer.put(active ? (byte) 1 : (byte) 0);
        if (active) {
            byte[] textBytes = text != null ? text.getBytes() : new byte[0];
            buffer.putInt(textBytes.length);
            buffer.put(textBytes);
            buffer.putInt(selectionStart);
            buffer.putInt(selectionEnd);
            buffer.putInt(compositionStart);
            buffer.putInt(compositionEnd);
            buffer.putInt(cursorRectLeft);
            buffer.putInt(cursorRectTop);
            buffer.putInt(cursorRectRight);
            buffer.putInt(cursorRectBottom);
        }
    }

    public static TextInputState decode(ByteBuffer buffer) {
        boolean active = buffer.get() == 1;
        if (!active) return new TextInputState(false, "", 0, 0, 0, 0, 0, 0, 0, 0);
        
        int textLen = buffer.getInt();
        byte[] textBytes = new byte[textLen];
        buffer.get(textBytes);
        String text = new String(textBytes);
        int selectionStart = buffer.getInt();
        int selectionEnd = buffer.getInt();
        int compositionStart = buffer.getInt();
        int compositionEnd = buffer.getInt();
        int cursorRectLeft = buffer.getInt();
        int cursorRectTop = buffer.getInt();
        int cursorRectRight = buffer.getInt();
        int cursorRectBottom = buffer.getInt();
        
        return new TextInputState(active, text, selectionStart, selectionEnd,
                compositionStart, compositionEnd,
                cursorRectLeft, cursorRectTop, cursorRectRight, cursorRectBottom);
    }

    @Override
    public String toString() {
        return "TextInputState{active=" + active + ", text='" + text + '\'' +
                ", selection=[" + selectionStart + "," + selectionEnd + "]}";
    }
}