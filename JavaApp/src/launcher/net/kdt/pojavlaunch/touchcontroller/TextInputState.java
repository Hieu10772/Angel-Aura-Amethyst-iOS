package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Text input status. Wire format matches the current TouchController
 * protocol: [hasData:1][textLen:4][text][compStart:4][compLen:4]
 * [selStart:4][selLen:4][selLeft:1], ranges in UTF-8 byte offsets.
 */
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

    // Convert a UTF-8 byte offset to a UTF-16 code unit index.
    private static int utf8ToUtf16Offset(String text, int byteOffset) {
        byte[] bytes = text.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        if (byteOffset < 0) byteOffset = 0;
        if (byteOffset > bytes.length) byteOffset = bytes.length;
        int utf16 = 0;
        int i = 0;
        while (i < byteOffset) {
            int b = bytes[i] & 0xFF;
            if (b < 0x80) {
                i += 1;
                utf16 += 1;
            } else if ((b & 0xE0) == 0xC0) {
                i += 2;
                utf16 += 1;
            } else if ((b & 0xF0) == 0xE0) {
                i += 3;
                utf16 += 1;
            } else if ((b & 0xF8) == 0xF0) {
                i += 4;
                utf16 += 2;
            } else {
                i += 1;
                utf16 += 1;
            }
        }
        return utf16;
    }

    public void encode(ByteBuffer buffer) {
        buffer.put(active ? (byte) 1 : (byte) 0);
        if (active) {
            byte[] textBytes = text != null ? text.getBytes(java.nio.charset.StandardCharsets.UTF_8) : new byte[0];
            buffer.putInt(textBytes.length);
            buffer.put(textBytes);
            // Ranges in UTF-8 byte offsets (selection/composition length in bytes)
            int selStart = text != null ? textToByteOffset(text, selectionStart) : 0;
            int selLen = text != null ? textToByteOffset(text, selectionEnd) - selStart : 0;
            int compStart = text != null ? textToByteOffset(text, compositionStart) : 0;
            int compLen = text != null ? textToByteOffset(text, compositionEnd) - compStart : 0;
            buffer.putInt(compStart);
            buffer.putInt(compLen);
            buffer.putInt(selStart);
            buffer.putInt(selLen);
            buffer.put((byte) 1);
        }
    }

    private static int textToByteOffset(String text, int utf16Offset) {
        byte[] bytes = text.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        if (utf16Offset <= 0) return 0;
        int i = 0;
        int utf16 = 0;
        while (i < bytes.length && utf16 < utf16Offset) {
            int b = bytes[i] & 0xFF;
            if (b < 0x80) {
                i += 1;
                utf16 += 1;
            } else if ((b & 0xE0) == 0xC0) {
                i += 2;
                utf16 += 1;
            } else if ((b & 0xF0) == 0xE0) {
                i += 3;
                utf16 += 1;
            } else if ((b & 0xF8) == 0xF0) {
                i += 4;
                utf16 += 2;
            } else {
                i += 1;
                utf16 += 1;
            }
        }
        return i;
    }

    public static TextInputState decode(ByteBuffer buffer) {
        boolean hasData = buffer.get() != 0;
        if (!hasData) return new TextInputState(false, "", 0, 0, 0, 0, 0, 0, 0, 0);

        int textLen = buffer.getInt();
        byte[] textBytes = new byte[textLen];
        buffer.get(textBytes);
        String text = new String(textBytes, java.nio.charset.StandardCharsets.UTF_8);

        int compStart = buffer.getInt();
        int compLen = buffer.getInt();
        int selStart = buffer.getInt();
        int selLen = buffer.getInt();
        buffer.get(); // selectionLeft

        int compositionStart = utf8ToUtf16Offset(text, compStart);
        int compositionEnd = utf8ToUtf16Offset(text, compStart + compLen);
        int selectionStart = utf8ToUtf16Offset(text, selStart);
        int selectionEnd = utf8ToUtf16Offset(text, selStart + selLen);

        return new TextInputState(true, text, selectionStart, selectionEnd,
                compositionStart, compositionEnd, 0, 0, 0, 0);
    }

    @Override
    public String toString() {
        return "TextInputState{active=" + active + ", text='" + text + '\'' +
                ", selection=[" + selectionStart + "," + selectionEnd + "]}";
    }
}