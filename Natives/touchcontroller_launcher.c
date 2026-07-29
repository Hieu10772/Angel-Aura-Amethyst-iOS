/*
 * TouchController iOS Launcher JNI Bridge
 * Connects Java launcher to mod's ring buffer transport
 */

#include <jni.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "touchcontroller_launcher.h"

// Ring buffer structure (must match mod's ios.c)
#define MAX_QUEUE_SIZE (4 * 1024)

typedef struct ring_buffer {
    uint8_t* data;
    size_t capacity;
    size_t read_pos;
    size_t write_pos;
    size_t size;
    pthread_mutex_t mutex;
} ring_buffer_t;

typedef struct {
    ring_buffer_t* write_buffer;  // Launcher -> Mod
    ring_buffer_t* read_buffer;   // Mod -> Launcher
} transport_handle_t;

// Ring buffer functions
static ring_buffer_t* ring_buffer_alloc(size_t capacity) {
    ring_buffer_t* rb = malloc(sizeof(ring_buffer_t));
    if (!rb) return NULL;
    
    rb->data = malloc(capacity);
    if (!rb->data) {
        free(rb);
        return NULL;
    }
    
    rb->capacity = capacity;
    rb->read_pos = 0;
    rb->write_pos = 0;
    rb->size = 0;
    pthread_mutex_init(&rb->mutex, NULL);
    return rb;
}

static void ring_buffer_free(ring_buffer_t* rb) {
    if (rb) {
        pthread_mutex_destroy(&rb->mutex);
        free(rb->data);
        free(rb);
    }
}

static int ring_buffer_write(ring_buffer_t* rb, const void* data, size_t len) {
    if (!rb || len > rb->capacity - rb->size) return -1;
    
    pthread_mutex_lock(&rb->mutex);
    
    size_t first_chunk = rb->capacity - rb->write_pos;
    if (len <= first_chunk) {
        memcpy(rb->data + rb->write_pos, data, len);
        rb->write_pos = (rb->write_pos + len) % rb->capacity;
    } else {
        memcpy(rb->data + rb->write_pos, data, first_chunk);
        memcpy(rb->data, (const uint8_t*)data + first_chunk, len - first_chunk);
        rb->write_pos = len - first_chunk;
    }
    rb->size += len;
    
    pthread_mutex_unlock(&rb->mutex);
    return 0;
}

static int ring_buffer_read(ring_buffer_t* rb, void* data, size_t len) {
    if (!rb || len > rb->size) return -1;
    
    pthread_mutex_lock(&rb->mutex);
    
    size_t first_chunk = rb->capacity - rb->read_pos;
    if (len <= first_chunk) {
        memcpy(data, rb->data + rb->read_pos, len);
        rb->read_pos = (rb->read_pos + len) % rb->capacity;
    } else {
        memcpy(data, rb->data + rb->read_pos, first_chunk);
        memcpy((uint8_t*)data + first_chunk, rb->data, len - first_chunk);
        rb->read_pos = len - first_chunk;
    }
    rb->size -= len;
    
    pthread_mutex_unlock(&rb->mutex);
    return 0;
}

// Message format: [length:1][data:length]
static int write_message(ring_buffer_t* rb, const void* data, size_t len) {
    if (len > 255) return -1;
    uint8_t header = (uint8_t)len;
    if (ring_buffer_write(rb, &header, 1) != 0) return -1;
    return ring_buffer_write(rb, data, len);
}

static int read_message(ring_buffer_t* rb, void* buffer, size_t max_len) {
    uint8_t header;
    if (ring_buffer_read(rb, &header, 1) != 0) return -1;
    size_t len = header;
    if (len > max_len) return -1;
    if (len == 0) return 0;
    return ring_buffer_read(rb, buffer, len) == 0 ? (int)len : -1;
}

// Global transport handle (singleton)
static transport_handle_t* g_transport = NULL;

// ===== JNI Methods for IosSocketTransport =====

JNIEXPORT jlong JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosSocketTransport_nativeInit(JNIEnv* env, jclass clazz, jstring socketName) {
    transport_handle_t* handle = malloc(sizeof(transport_handle_t));
    if (!handle) return 0;
    
    handle->write_buffer = ring_buffer_alloc(MAX_QUEUE_SIZE);
    handle->read_buffer = ring_buffer_alloc(MAX_QUEUE_SIZE);
    
    if (!handle->write_buffer || !handle->read_buffer) {
        if (handle->write_buffer) ring_buffer_free(handle->write_buffer);
        if (handle->read_buffer) ring_buffer_free(handle->read_buffer);
        free(handle);
        return 0;
    }
    
    // socketName is kept for compatibility but not used on iOS
    // (mod and launcher share same JVM process)
    const char* name = (*env)->GetStringUTFChars(env, socketName, NULL);
    (*env)->ReleaseStringUTFChars(env, socketName, name);
    
    g_transport = handle;
    return (jlong)handle;
}

JNIEXPORT jint JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosSocketTransport_nativeReceive(JNIEnv* env, jclass clazz, jlong handlePtr, jbyteArray buffer) {
    transport_handle_t* handle = (transport_handle_t*)handlePtr;
    if (!handle || !handle->read_buffer) return -1;
    
    jsize arrayLen = (*env)->GetArrayLength(env, buffer);
    jbyte* data = (*env)->GetByteArrayElements(env, buffer, NULL);
    if (!data) return -1;
    
    int result = read_message(handle->read_buffer, data, arrayLen);
    (*env)->ReleaseByteArrayElements(env, buffer, data, 0);
    
    return result;
}

JNIEXPORT void JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosSocketTransport_nativeSend(JNIEnv* env, jclass clazz, jlong handlePtr, jbyteArray buffer, jint offset, jint length) {
    transport_handle_t* handle = (transport_handle_t*)handlePtr;
    if (!handle || !handle->write_buffer || length <= 0) return;
    
    jbyte* data = (*env)->GetByteArrayElements(env, buffer, NULL);
    if (data) {
        write_message(handle->write_buffer, data + offset, length);
        (*env)->ReleaseByteArrayElements(env, buffer, data, JNI_ABORT);
    }
}

JNIEXPORT void JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosSocketTransport_nativeClose(JNIEnv* env, jclass clazz, jlong handlePtr) {
    transport_handle_t* handle = (transport_handle_t*)handlePtr;
    if (!handle) return;
    
    ring_buffer_free(handle->write_buffer);
    ring_buffer_free(handle->read_buffer);
    free(handle);
    
    if (g_transport == handle) g_transport = NULL;
}

// ===== JNI Methods for IosVibrationHandler =====

JNIEXPORT void JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosVibrationHandler_nativeVibrate(JNIEnv* env, jobject obj, jint type) {
    touchcontroller_vibrate(type);
}

// ===== JNI Methods for IosKeyboardShowHandler =====

JNIEXPORT void JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosKeyboardShowHandler_nativeShowKeyboard(JNIEnv* env, jclass clazz) {
    touchcontroller_showKeyboard();
}

JNIEXPORT void JNICALL
Java_net_kdt_pojavlaunch_touchcontroller_IosKeyboardShowHandler_nativeHideKeyboard(JNIEnv* env, jclass clazz) {
    touchcontroller_hideKeyboard();
}