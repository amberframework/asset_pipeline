#include <jni.h>

extern void crystal_init(void);
extern void *crystal_android_host_render_slug(void *env, void *context, const char *slug);
extern void crystal_ui_callback_dispatch(unsigned long long tag);
extern void crystal_ui_string_callback_dispatch(unsigned long long tag, unsigned char *value);
extern void crystal_ui_bool_callback_dispatch(unsigned long long tag, int value);
extern void crystal_ui_float_callback_dispatch(unsigned long long tag, double value);
extern void crystal_ui_int_callback_dispatch(unsigned long long tag, int value);

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm;
    (void)reserved;
    crystal_init();
    return JNI_VERSION_1_6;
}

JNIEXPORT jobject JNICALL
Java_dev_assetpipeline_androidhost_CrystalBridge_renderStudy(JNIEnv *env, jobject thiz, jobject context, jstring slug) {
    (void)thiz;

    if (!context || !slug) {
        return NULL;
    }

    const char *slug_utf8 = (*env)->GetStringUTFChars(env, slug, NULL);
    void *global_ref = crystal_android_host_render_slug(env, context, slug_utf8);
    (*env)->ReleaseStringUTFChars(env, slug, slug_utf8);

    if (!global_ref) {
        return NULL;
    }

    return (*env)->NewLocalRef(env, (jobject)global_ref);
}

JNIEXPORT void JNICALL
Java_dev_assetpipeline_androidhost_CrystalBridge_dispatchVoidCallbackNative(JNIEnv *env, jclass clazz, jlong callback_id) {
    (void)env;
    (void)clazz;
    crystal_ui_callback_dispatch((unsigned long long)callback_id);
}

JNIEXPORT void JNICALL
Java_dev_assetpipeline_androidhost_CrystalBridge_dispatchStringCallbackNative(JNIEnv *env, jclass clazz, jlong callback_id, jstring value) {
    (void)clazz;

    if (!value) {
        crystal_ui_string_callback_dispatch((unsigned long long)callback_id, (unsigned char *)"");
        return;
    }

    const char *utf8 = (*env)->GetStringUTFChars(env, value, NULL);
    crystal_ui_string_callback_dispatch((unsigned long long)callback_id, (unsigned char *)utf8);
    (*env)->ReleaseStringUTFChars(env, value, utf8);
}

JNIEXPORT void JNICALL
Java_dev_assetpipeline_androidhost_CrystalBridge_dispatchBoolCallbackNative(JNIEnv *env, jclass clazz, jlong callback_id, jboolean value) {
    (void)env;
    (void)clazz;
    crystal_ui_bool_callback_dispatch((unsigned long long)callback_id, value ? 1 : 0);
}

JNIEXPORT void JNICALL
Java_dev_assetpipeline_androidhost_CrystalBridge_dispatchFloatCallbackNative(JNIEnv *env, jclass clazz, jlong callback_id, jdouble value) {
    (void)env;
    (void)clazz;
    crystal_ui_float_callback_dispatch((unsigned long long)callback_id, (double)value);
}

JNIEXPORT void JNICALL
Java_dev_assetpipeline_androidhost_CrystalBridge_dispatchIntCallbackNative(JNIEnv *env, jclass clazz, jlong callback_id, jint value) {
    (void)env;
    (void)clazz;
    crystal_ui_int_callback_dispatch((unsigned long long)callback_id, (int)value);
}
