/*
 * TouchController iOS Game JNI Bridge
 *
 * JNI stubs for the game-side transport
 * (top.fifthlight.touchcontroller.common.platform.ios.Transport).
 *
 * These MUST stay inside the main executable (AngelAuraAmethyst): the game
 * runs in the Knot classloader, which is the only classloader that
 * System.load()s the executable (from LWJGL's Library.<clinit>). The
 * launcher-side JNI lives in libTouchControllerBridge.dylib instead, so the
 * two native libraries are registered with the two classloaders respectively
 * and never collide with "already loaded in another classloader".
 */

#include <jni.h>
#include <string.h>

#include "touchcontroller_launcher.h"

#define GAME_MAX_MESSAGE_SIZE 255

static void game_throw_exception(JNIEnv* env, const char* msg) {
    (*env)->ThrowNew(env, (*env)->FindClass(env, "java/lang/Exception"), msg);
}

JNIEXPORT void JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_init(JNIEnv* env, jclass clazz) {
    if (touchcontroller_queue_ensure() != 0) {
        game_throw_exception(env, "Failed to initialize queue");
    }
}

JNIEXPORT jint JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive(JNIEnv* env, jclass clazz, jbyteArray buffer) {
    if (buffer == NULL) {
        game_throw_exception(env, "Buffer is null");
        return 0;
    }

    jsize arrayLen = (*env)->GetArrayLength(env, buffer);
    jbyte* data = (*env)->GetByteArrayElements(env, buffer, NULL);
    if (data == NULL) return -1;

    int result = touchcontroller_ios_receive(data);
    if (result < 0) {
        (*env)->ReleaseByteArrayElements(env, buffer, data, 0);
        game_throw_exception(env, "Queue not initialized");
        return 0;
    }
    (*env)->ReleaseByteArrayElements(env, buffer, data, 0);
    return result;
}

JNIEXPORT void JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_send(JNIEnv* env, jclass clazz, jbyteArray buffer, jint off, jint len) {
    if (buffer == NULL) {
        game_throw_exception(env, "Buffer is null");
        return;
    }
    if (len <= 0 || len > GAME_MAX_MESSAGE_SIZE) {
        game_throw_exception(env, "Bad message size");
        return;
    }

    jbyte* data = (*env)->GetByteArrayElements(env, buffer, NULL);
    if (data == NULL) return;

    int result = touchcontroller_ios_send(data + off, len);
    (*env)->ReleaseByteArrayElements(env, buffer, data, JNI_ABORT);
    if (result != 0) {
        game_throw_exception(env, "Queue not initialized");
    }
}
