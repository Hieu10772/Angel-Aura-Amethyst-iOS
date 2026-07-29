package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

/**
 * Transport interface matching TouchController's MessageTransport
 */
public interface MessageTransport extends AutoCloseable {
    void send(ByteBuffer buffer);
    boolean receive(ByteBuffer buffer);
}