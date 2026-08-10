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
#include <stdio.h>
#include <string.h>

#include "touchcontroller_launcher.h"

// Diagnostic logging: writes to process stderr, which the launcher captures
// into the JVM log file (latestlog.txt) alongside Java output.
#define TCG_LOG(...) fprintf(stderr, "[TCG] " __VA_ARGS__)

#define GAME_MAX_MESSAGE_SIZE 255

static void game_throw_exception(JNIEnv* env, const char* msg) {
    (*env)->ThrowNew(env, (*env)->FindClass(env, "java/lang/Exception"), msg);
}

JNIEXPORT jint JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__3BI(JNIEnv* env, jclass clazz, jbyteArray buffer);

JNIEXPORT void JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_send__3BII(JNIEnv* env, jclass clazz, jbyteArray buffer, jint off, jint len);

JNIEXPORT jlong JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_new__Ljava_lang_String_2J(JNIEnv* env, jclass clazz, jstring name);

// Spec-correct JNI mangling aliases. The JVM derives the looked-up symbol
// from the method's argument types only ("__" + mangled args, no return
// type), and non-overloaded methods get no suffix at all, e.g.:
//   new(String)J       -> Transport_new
//   receive(J,[B)I     -> Transport_receive__J_3B
//   receive([B)I       -> Transport_receive__3B
//   send(J,[B,I,I)V    -> Transport_send__J_3BII
//   send([B,I,I)V      -> Transport_send__3BII
//   init()V            -> Transport_init
// Export both spellings so whichever name the JVM looks up resolves.

JNIEXPORT jlong JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_new(JNIEnv* env, jclass clazz, jstring name) {
    return Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_new__Ljava_lang_String_2J(env, clazz, name);
}

JNIEXPORT jint JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__J_3B(JNIEnv* env, jclass clazz, jlong handle, jbyteArray buffer) {
    return Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__3BI(env, clazz, buffer);
}

JNIEXPORT jint JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__3B(JNIEnv* env, jclass clazz, jbyteArray buffer) {
    return Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__3BI(env, clazz, buffer);
}

JNIEXPORT void JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_init(JNIEnv* env, jclass clazz) {
    if (touchcontroller_queue_ensure() != 0) {
        game_throw_exception(env, "Failed to initialize queue");
    }
}

// Newer mod versions (0.3.1-alpha13+) use handle-based JNI:
//   Transport.new(String):long
//   Transport.receive(long, byte[]):int
//   Transport.send(long, byte[], int, int)
// The handle is opaque; the queue itself is process-global, so we just
// return a non-zero sentinel once the queue is ready.

JNIEXPORT jlong JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_new__Ljava_lang_String_2J(JNIEnv* env, jclass clazz, jstring name) {
    return touchcontroller_queue_ensure() == 0 ? (jlong)1 : 0;
}

JNIEXPORT jint JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__J_3BI(JNIEnv* env, jclass clazz, jlong handle, jbyteArray buffer) {
    return Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__3BI(env, clazz, buffer);
}

JNIEXPORT void JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_send__J_3BII(JNIEnv* env, jclass clazz, jlong handle, jbyteArray buffer, jint off, jint len) {
    Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_send__3BII(env, clazz, buffer, off, len);
}

JNIEXPORT jint JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_receive__3BI(JNIEnv* env, jclass clazz, jbyteArray buffer) {
    if (buffer == NULL) {
        game_throw_exception(env, "Buffer is null");
        return 0;
    }

    jsize arrayLen = (*env)->GetArrayLength(env, buffer);
    jbyte* data = (*env)->GetByteArrayElements(env, buffer, NULL);
    if (data == NULL) return -1;

    // One-shot + sparse polling markers: the mod calls receive() every
    // render frame; log the first poll and every 1000th so we can confirm
    // the mod is actually polling the shared queue.
    static int pollCount = 0;
    int poll = ++pollCount;
    if (poll == 1 || poll % 1000 == 0) {
        TCG_LOG("game poll #%d (buffer size=%d)\n", poll, (int)arrayLen);
    }

    int result = touchcontroller_ios_receive(data, (size_t)arrayLen);
    if (result < 0) {
        (*env)->ReleaseByteArrayElements(env, buffer, data, 0);
        game_throw_exception(env, "Queue not initialized");
        return 0;
    }
    if (result > 0) {
        int type = (result >= 4)
            ? ((data[0] & 0xFF) << 24) | ((data[1] & 0xFF) << 16) | ((data[2] & 0xFF) << 8) | (data[3] & 0xFF)
            : -1;
        TCG_LOG("game receive n=%d type=%d\n", result, type);
    }
    (*env)->ReleaseByteArrayElements(env, buffer, data, 0);
    return result;
}

JNIEXPORT void JNICALL
Java_top_fifthlight_touchcontroller_common_platform_ios_Transport_send__3BII(JNIEnv* env, jclass clazz, jbyteArray buffer, jint off, jint len) {
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
    if (result == 0 && len >= 4) {
        int type = ((data[off] & 0xFF) << 24) | ((data[off + 1] & 0xFF) << 16)
            | ((data[off + 2] & 0xFF) << 8) | (data[off + 3] & 0xFF);
        TCG_LOG("game send n=%d type=%d\n", len, type);
    }
    (*env)->ReleaseByteArrayElements(env, buffer, data, JNI_ABORT);
    if (result != 0) {
        game_throw_exception(env, "Queue not initialized");
    }
}
