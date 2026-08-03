/*
 * TouchController iOS JNI Bridge
 * Connects native touch events from input_bridge_v3.m to Java TouchControllerManager
 */

#include <jni.h>
#include <stdatomic.h>

#include "touchcontroller_jni_bridge.h"

// Global JVM reference
static JavaVM* g_javaVM = NULL;

// Method IDs for TouchControllerManager (all static)
static jclass g_touchControllerManagerClass = NULL;
static jmethodID g_onTouchDownMethod = NULL;
static jmethodID g_onTouchMoveMethod = NULL;
static jmethodID g_onTouchUpMethod = NULL;
static jmethodID g_onTouchCancelMethod = NULL;
static jmethodID g_onViewMoveMethod = NULL;

static void resolve_methods(JNIEnv* env) {
    jclass clazz = (*env)->FindClass(env, "net/kdt/pojavlaunch/touchcontroller/TouchControllerManager");
    if (!clazz) {
        if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
        return;
    }
    if (g_touchControllerManagerClass != NULL) {
        (*env)->DeleteGlobalRef(env, g_touchControllerManagerClass);
    }
    g_touchControllerManagerClass = (*env)->NewGlobalRef(env, clazz);

    g_onTouchDownMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchDown", "(FF)I");
    g_onTouchMoveMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchMove", "(IFF)V");
    g_onTouchUpMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchUp", "(I)V");
    g_onTouchCancelMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchCancel", "()V");
    g_onViewMoveMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onViewMove", "(FF)V");
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionClear(env);
    }
}

// Initialize JNI references. May be called before the TouchControllerManager
// class is loaded (e.g. from JNI_OnLoad); resolution is retried lazily on
// first touch event, so an early failure is not fatal.
void touchcontroller_jni_init(JavaVM* vm) {
    g_javaVM = vm;

    JNIEnv* env;
    if ((*vm)->GetEnv(vm, (void**)&env, JNI_VERSION_1_4) != JNI_OK) {
        return;
    }
    resolve_methods(env);
}

// Ensure the method refs are resolved; self-heals if the class was not
// loadable when touchcontroller_jni_init was first called.
static JNIEnv* ensure_ready(void) {
    if (g_javaVM == NULL) return NULL;
    JNIEnv* env;
    if ((*g_javaVM)->AttachCurrentThread(g_javaVM, &env, NULL) != JNI_OK) {
        return NULL;
    }
    if (g_touchControllerManagerClass == NULL || g_onTouchDownMethod == NULL) {
        resolve_methods(env);
    }
    return env;
}

// Shutdown JNI references
void touchcontroller_jni_shutdown() {
    if (g_javaVM && g_touchControllerManagerClass) {
        JNIEnv* env;
        if ((*g_javaVM)->GetEnv(g_javaVM, (void**)&env, JNI_VERSION_1_4) == JNI_OK) {
            (*env)->DeleteGlobalRef(env, g_touchControllerManagerClass);
        }
        g_touchControllerManagerClass = NULL;
    }
}

// Called from input_bridge_v3.m when a touch begins (ACTION_DOWN)
// Returns pointer index assigned to this touch, or -1 on failure
int touchcontroller_onTouchDown(float x, float y) {
    JNIEnv* env = ensure_ready();
    if (env == NULL || g_touchControllerManagerClass == NULL || g_onTouchDownMethod == NULL) return -1;

    jint index = (*env)->CallStaticIntMethod(env, g_touchControllerManagerClass, g_onTouchDownMethod, x, y);
    return (int)index;
}

// Called from input_bridge_v3.m when a touch moves (ACTION_MOVE)
void touchcontroller_onTouchMove(int index, float x, float y) {
    JNIEnv* env = ensure_ready();
    if (env == NULL || g_touchControllerManagerClass == NULL || g_onTouchMoveMethod == NULL) return;

    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onTouchMoveMethod, index, x, y);
}

// Called from input_bridge_v3.m when a touch ends (ACTION_UP)
void touchcontroller_onTouchUp(int index) {
    JNIEnv* env = ensure_ready();
    if (env == NULL || g_touchControllerManagerClass == NULL || g_onTouchUpMethod == NULL) return;

    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onTouchUpMethod, index);
}

// Called from input_bridge_v3.m when all touches are cancelled
void touchcontroller_onTouchCancel() {
    JNIEnv* env = ensure_ready();
    if (env == NULL || g_touchControllerManagerClass == NULL || g_onTouchCancelMethod == NULL) return;

    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onTouchCancelMethod);
}

// Called for view movement (camera rotation via drag)
void touchcontroller_onViewMove(float deltaPitch, float deltaYaw) {
    JNIEnv* env = ensure_ready();
    if (env == NULL || g_touchControllerManagerClass == NULL || g_onViewMoveMethod == NULL) return;

    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onViewMoveMethod, deltaPitch, deltaYaw);
}