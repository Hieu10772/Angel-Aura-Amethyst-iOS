package net.kdt.pojavlaunch.touchcontroller;

import java.nio.ByteBuffer;

public abstract class ProxyMessage {
    public abstract ProxyMessageType getType();
    public abstract void encode(ByteBuffer buffer);
    
    public static ProxyMessage decode(int typeId, ByteBuffer buffer) {
        ProxyMessageType type = ProxyMessageType.fromId(typeId);
        if (type == null) return null;
        
        switch (type) {
            case ADD_POINTER:
                return AddPointerMessage.decode(buffer);
            case REMOVE_POINTER:
                return RemovePointerMessage.decode(buffer);
            case CLEAR_POINTER:
                return ClearPointerMessage.decode(buffer);
            case VIBRATE:
                return VibrateMessage.decode(buffer);
            case CAPABILITY:
                return CapabilityMessage.decode(buffer);
            case LARGE_MESSAGE:
                return LargeMessage.decode(buffer);
            case INPUT_STATUS:
                return InputStatusMessage.decode(buffer);
            case INPUT_CURSOR:
                return InputCursorMessage.decode(buffer);
            case INPUT_AREA:
                return InputAreaMessage.decode(buffer);
            case KEYBOARD_SHOW:
                return KeyboardShowMessage.decode(buffer);
            case INITIALIZE:
                return InitializeMessage.decode(buffer);
            case MOVE_VIEW:
                return MoveViewMessage.decode(buffer);
            default:
                return null;
        }
    }
}