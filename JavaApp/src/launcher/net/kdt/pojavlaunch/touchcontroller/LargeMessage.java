package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Chunk message used to transfer messages larger than 255 bytes.
 * Format: [length:1][end:1][payload].
 * Matches top.fifthlight.touchcontroller.proxy.message.LargeMessage.
 */
public final class LargeMessage extends ProxyMessage {
    public static final int MAX_PAYLOAD_LENGTH = 240;

    public final byte[] payload;
    public final boolean end;

    public LargeMessage(byte[] payload, boolean end) {
        this.payload = payload;
        this.end = end;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.LARGE_MESSAGE; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        buffer.put((byte) payload.length);
        buffer.put(end ? (byte) 1 : (byte) 0);
        buffer.put(payload);
    }

    public static LargeMessage decode(ByteBuffer buffer) {
        int length = buffer.get() & 0xFF;
        boolean end = buffer.get() == 1;
        byte[] payload = new byte[length];
        buffer.get(payload);
        return new LargeMessage(payload, end);
    }
}