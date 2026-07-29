/*
 * TouchController JNI Bridge Header
 * Connects native iOS touch events to Java TouchControllerManager
 */

#ifndef TOUCHCONTROLLER_JNI_BRIDGE_H
#define TOUCHCONTROLLER_JNI_BRIDGE_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialize JNI references (called from JNI_OnLoad in input_bridge_v3.m)
void touchcontroller_jni_init(JavaVM* vm);

// Shutdown JNI references
void touchcontroller_jni_shutdown();

// Touch event forwarding (called from input_bridge_v3.m / SurfaceViewController.m)
// Returns pointer index assigned to this touch, or -1 on failure
int touchcontroller_onTouchDown(float x, float y);
void touchcontroller_onTouchMove(int index, float x, float y);
void touchcontroller_onTouchUp(int index);
void touchcontroller_onTouchCancel();
void touchcontroller_onViewMove(float deltaPitch, float deltaYaw);

#ifdef __cplusplus
}
#endif

#endif // TOUCHCONTROLLER_JNI_BRIDGE_H