/*
 * TouchController Bridge Header
 * Connects native iOS touch events to the shared ring buffer queue consumed
 * by the TouchController mod. The touch path is pure C (no Java), so it is
 * independent of launcher/game classloaders.
 */

#ifndef TOUCHCONTROLLER_JNI_BRIDGE_H
#define TOUCHCONTROLLER_JNI_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

// No-op compatibility stubs (legacy JNI init/shutdown hooks)
void touchcontroller_jni_init(void* vm);
void touchcontroller_jni_shutdown(void);

// Touch event forwarding (called from input_bridge_v3.m / SurfaceViewController.m)
// Returns pointer index assigned to this touch, or -1 on failure
int touchcontroller_onTouchDown(float x, float y);
void touchcontroller_onTouchMove(int index, float x, float y);
void touchcontroller_onTouchUp(int index);
void touchcontroller_onTouchCancel(void);
void touchcontroller_onViewMove(float deltaPitch, float deltaYaw);

#ifdef __cplusplus
}
#endif

#endif // TOUCHCONTROLLER_JNI_BRIDGE_H