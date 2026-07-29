package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * iOS transport for TouchController using JNI to native ring buffer.
 * This connects to the same ring buffer that the mod's IosPlatform uses.
 */
public class IosSocketTransport implements MessageTransport {
    private static final String TAG = "IosSocketTransport";
    
    private long nativeHandle = 0;
    private boolean closed = false;
    private final byte[] readBuffer = new byte[256];

    static {
        System.loadLibrary("touchcontroller_launcher");
    }

    /**
     * Creates a new iOS transport connected to the mod's ring buffer.
     * @param socketName The socket name (must match TOUCH_CONTROLLER_PROXY_SOCKET env var)
     */
    public static IosSocketTransport create(String socketName) {
        IosSocketTransport transport = new IosSocketTransport();
        transport.nativeHandle = nativeInit(socketName);
        if (transport.nativeHandle == 0) {
            throw new RuntimeException("Failed to initialize iOS transport");
        }
        return transport;
    }

    @Override
    public void send(ByteBuffer buffer) {
        if (closed) return;
        
        int remaining = buffer.remaining();
        if (remaining > 255) {
            throw new IllegalArgumentException("Message too big: " + remaining);
        }
        if (remaining == 0) {
            throw new IllegalArgumentException("Empty message");
        }

        byte[] sendBuffer = new byte[remaining + 1];
        sendBuffer[0] = (byte) remaining;
        
        if (buffer.hasArray() && !buffer.isReadOnly()) {
            byte[] array = buffer.array();
            System.arraycopy(array, buffer.position() + buffer.arrayOffset(), sendBuffer, 1, remaining);
        } else {
            buffer.get(sendBuffer, 1, remaining);
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
    private static native long nativeInit(String socketName);
    private static native int nativeReceive(long handle, byte[] buffer);
    private static native void nativeSend(long handle, byte[] buffer, int offset, int length);
    private static native void nativeClose(long handle);
}