package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public final class CapabilityMessage extends ProxyMessage {
    public final String capabilityId;
    public final boolean enabled;

    public CapabilityMessage(String capabilityId, boolean enabled) {
        this.capabilityId = capabilityId;
        this.enabled = enabled;
    }

    @Override
    public ProxyMessageType getType() { return ProxyMessageType.CAPABILITY; }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putInt(getType().id);
        byte[] capBytes = capabilityId.getBytes();
        buffer.putInt(capBytes.length);
        buffer.put(capBytes);
        buffer.put(enabled ? (byte) 1 : (byte) 0);
    }

    public static CapabilityMessage decode(ByteBuffer buffer) {
        int len = buffer.getInt();
        byte[] capBytes = new byte[len];
        buffer.get(capBytes);
        String capId = new String(capBytes);
        boolean enabled = buffer.get() == 1;
        return new CapabilityMessage(capId, enabled);
    }
}