package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * iOS transport for TouchController using JNI to the shared in-process ring
 * buffer queue. The queue is shared with the game-side Transport
 * (top.fifthlight.touchcontroller.common.platform.ios.Transport) so the mod
 * and the launcher exchange raw messages with no length prefix.
 */
public class IosSocketTransport implements MessageTransport {
    private static final String TAG = "IosSocketTransport";

    private long nativeHandle = 0;
    private boolean closed = false;
    private final byte[] readBuffer = new byte[256];

    // The JNI natives live inside the main executable (AngelAuraAmethyst),
    // which is System.load()'d into the JVM at startup (see UIKit.java), so
    // no separate library is loaded here.

    /**
     * Creates a new iOS transport connected to the shared ring buffer queue.
     */
    public static IosSocketTransport create() {
        IosSocketTransport transport = new IosSocketTransport();
        transport.nativeHandle = nativeInit();
        if (transport.nativeHandle == 0) {
            throw new RuntimeException("Failed to initialize iOS transport");
        }
        return transport;
    }

    @Override
    public void send(ByteBuffer buffer) {
        if (closed) return;

        int remaining = buffer.remaining();
        if (remaining == 0) {
            throw new IllegalArgumentException("Empty message");
        }

        byte[] sendBuffer = new byte[remaining];

        if (buffer.hasArray() && !buffer.isReadOnly()) {
            byte[] array = buffer.array();
            System.arraycopy(array, buffer.position() + buffer.arrayOffset(), sendBuffer, 0, remaining);
        } else {
            buffer.get(sendBuffer);
        }

        nativeSend(nativeHandle, sendBuffer, 0, sendBuffer.length);
    }

    @Override
    public boolean receive(ByteBuffer buffer) {
        if (closed) return false;

        int length = nativeReceive(nativeHandle, readBuffer);
        if (length <= 0) return false;

        if (buffer.remaining() < length) {
            throw new IllegalArgumentException("Buffer overflow: packet length is " + length +
                ", but the buffer only has " + buffer.remaining());
        }

        buffer.put(readBuffer, 0, length);
        return true;
    }

    @Override
    public void close() {
        if (!closed) {
            closed = true;
            if (nativeHandle != 0) {
                nativeClose(nativeHandle);
                nativeHandle = 0;
            }
        }
    }

    // Native methods
    private static native long nativeInit();
    private static native int nativeReceive(long handle, byte[] buffer);
    private static native void nativeSend(long handle, byte[] buffer, int offset, int length);
    private static native void nativeClose(long handle);
}