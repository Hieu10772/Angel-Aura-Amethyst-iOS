package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Low-level message client for sending/receiving raw messages.
 */
public class LauncherProxyMessageClient {
    private final MessageTransport transport;
    private final ByteBuffer sendBuffer = ByteBuffer.allocate(1024);
    private final ByteBuffer receiveBuffer = ByteBuffer.allocate(1024);

    public LauncherProxyMessageClient(MessageTransport transport) {
        this.transport = transport;
    }

    public void run() {
        // Transport is already running in its own thread
    }

    public void send(ProxyMessage message) {
        sendBuffer.clear();
        message.encode(sendBuffer);
        sendBuffer.flip();
        transport.send(sendBuffer);
    }

    public boolean receive(ByteBuffer buffer) {
        receiveBuffer.clear();
        boolean result = transport.receive(receiveBuffer);
        if (result) {
            receiveBuffer.flip();
            int remaining = receiveBuffer.remaining();
            if (buffer.remaining() >= remaining) {
                buffer.put(receiveBuffer);
            }
        }
        return result;
    }

    public void close() throws Exception {
        transport.close();
    }
}