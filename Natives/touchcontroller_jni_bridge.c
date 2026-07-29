/*
 * TouchController iOS JNI Bridge
 * Connects native touch events from input_bridge_v3.m to Java TouchControllerManager
 */

#include <jni.h>
#include <stdatomic.h>

// Global JVM reference
static JavaVM* g_javaVM = NULL;

// Method IDs for TouchControllerManager
static jclass g_touchControllerManagerClass = NULL;
static jmethodID g_onTouchDownMethod = NULL;
static jmethodID g_onTouchMoveMethod = NULL;
static jmethodID g_onTouchUpMethod = NULL;
static jmethodID g_onTouchCancelMethod = NULL;
static jmethodID g_onViewMoveMethod = NULL;

// Initialize JNI references (called from JNI_OnLoad)
void touchcontroller_jni_init(JavaVM* vm) {
    g_javaVM = vm;
    
    JNIEnv* env;
    if ((*vm)->GetEnv(vm, (void**)&env, JNI_VERSION_1_4) != JNI_OK) {
        return;
    }
    
    jclass clazz = (*env)->FindClass(env, "net/kdt/pojavlaunch/touchcontroller/TouchControllerManager");
    if (!clazz) {
        return;
    }
    
    g_touchControllerManagerClass = (*env)->NewGlobalRef(env, clazz);
    
    g_onTouchDownMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchDown", "(FF)I");
    g_onTouchMoveMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchMove", "(IFF)V");
    g_onTouchUpMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchUp", "(I)V");
    g_onTouchCancelMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onTouchCancel", "()V");
    g_onViewMoveMethod = (*env)->GetStaticMethodID(env, g_touchControllerManagerClass, "onViewMove", "(FF)V");
}

// Shutdown JNI references
void touchcontroller_jni_shutdown() {
    if (g_javaVM && g_touchControllerManagerClass) {
        JNIEnv* env;
        if ((*g_javaVM)->GetEnv(g_javaVM, (void**)&env, JNI_VERSION_1_4) == JNI_OK) {
            (*env)->DeleteGlobalRef(env, g_touchControllerManagerClass);
            g_touchControllerManagerClass = NULL;
        }
    }
}

// Called from input_bridge_v3.m when a touch begins (ACTION_DOWN)
// Returns pointer index assigned to this touch
int touchcontroller_onTouchDown(float x, float y) {
    if (!g_touchControllerManagerClass || !g_onTouchDownMethod) return -1;
    
    JNIEnv* env;
    if ((*g_javaVM)->AttachCurrentThread(g_javaVM, &env, NULL) != JNI_OK) {
        return -1;
    }
    
    jint index = (*env)->CallStaticIntMethod(env, g_touchControllerManagerClass, g_onTouchDownMethod, x, y);
    
    (*g_javaVM)->DetachCurrentThread(g_javaVM);
    return (int)index;
}

// Called from input_bridge_v3.m when a touch moves (ACTION_MOVE)
void touchcontroller_onTouchMove(int index, float x, float y) {
    if (!g_touchControllerManagerClass || !g_onTouchMoveMethod) return;
    
    JNIEnv* env;
    if ((*g_javaVM)->AttachCurrentThread(g_javaVM, &env, NULL) != JNI_OK) {
        return;
    }
    
    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onTouchMoveMethod, index, x, y);
    
    (*g_javaVM)->DetachCurrentThread(g_javaVM);
}

// Called from input_bridge_v3.m when a touch ends (ACTION_UP)
void touchcontroller_onTouchUp(int index) {
    if (!g_touchControllerManagerClass || !g_onTouchUpMethod) return;
    
    JNIEnv* env;
    if ((*g_javaVM)->AttachCurrentThread(g_javaVM, &env, NULL) != JNI_OK) {
        return;
    }
    
    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onTouchUpMethod, index);
    
    (*g_javaVM)->DetachCurrentThread(g_javaVM);
}

// Called from input_bridge_v3.m when all touches are cancelled
void touchcontroller_onTouchCancel() {
    if (!g_touchControllerManagerClass || !g_onTouchCancelMethod) return;
    
    JNIEnv* env;
    if ((*g_javaVM)->AttachCurrentThread(g_javaVM, &env, NULL) != JNI_OK) {
        return;
    }
    
    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onTouchCancelMethod);
    
    (*g_javaVM)->DetachCurrentThread(g_javaVM);
}

// Called for view movement (camera rotation via drag)
void touchcontroller_onViewMove(float deltaPitch, float deltaYaw) {
    if (!g_touchControllerManagerClass || !g_onViewMoveMethod) return;
    
    JNIEnv* env;
    if ((*g_javaVM)->AttachCurrentThread(g_javaVM, &env, NULL) != JNI_OK) {
        return;
    }
    
    (*env)->CallStaticVoidMethod(env, g_touchControllerManagerClass, g_onViewMoveMethod, deltaPitch, deltaYaw);
    
    (*g_javaVM)->DetachCurrentThread(g_javaVM);
}