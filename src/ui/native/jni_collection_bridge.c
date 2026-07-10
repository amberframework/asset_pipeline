#include <jni.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static jstring ap_new_string(JNIEnv *env, const uint8_t *bytes, jint byte_len) {
    if (!bytes) {
        return NULL;
    }

    if (byte_len < 0) {
        byte_len = (jint)strlen((const char *)bytes);
    }

    char *buffer = (char *)malloc((size_t)byte_len + 1U);
    if (!buffer) {
        return NULL;
    }

    memcpy(buffer, bytes, (size_t)byte_len);
    buffer[byte_len] = '\0';
    jstring str = (*env)->NewStringUTF(env, buffer);
    free(buffer);
    return str;
}

void *jni_string_create(void *env_ptr, uint8_t *utf8_str) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return ap_new_string(env, utf8_str, -1);
}

void *jni_string_create_with_bytes(void *env_ptr, uint8_t *bytes, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return ap_new_string(env, bytes, byte_len);
}

uint8_t *jni_string_to_utf8(void *env_ptr, void *jstr, int32_t *out_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    const char *utf8 = (*env)->GetStringUTFChars(env, (jstring)jstr, NULL);
    if (out_len) {
        *out_len = utf8 ? (int32_t)strlen(utf8) : 0;
    }
    return (uint8_t *)utf8;
}

void jni_string_release_utf8(void *env_ptr, void *jstr, uint8_t *utf8) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    if (utf8) {
        (*env)->ReleaseStringUTFChars(env, (jstring)jstr, (const char *)utf8);
    }
}

int32_t jni_string_length(void *env_ptr, void *jstr) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (int32_t)(*env)->GetStringLength(env, (jstring)jstr);
}

void *jni_object_array_create(void *env_ptr, uint8_t *element_class, void **objects, int32_t count) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->FindClass(env, (const char *)element_class);
    jobjectArray array = (*env)->NewObjectArray(env, count, cls, NULL);
    for (int32_t index = 0; index < count; index++) {
        (*env)->SetObjectArrayElement(env, array, index, (jobject)objects[index]);
    }
    (*env)->DeleteLocalRef(env, cls);
    return array;
}

int32_t jni_object_array_length(void *env_ptr, void *jarr) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (int32_t)(*env)->GetArrayLength(env, (jarray)jarr);
}

void *jni_object_array_get(void *env_ptr, void *jarr, int32_t index) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (*env)->GetObjectArrayElement(env, (jobjectArray)jarr, index);
}

void *jni_arraylist_create(void *env_ptr, void **objects, int32_t count) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->FindClass(env, "java/util/ArrayList");
    jmethodID ctor = (*env)->GetMethodID(env, cls, "<init>", "(I)V");
    jmethodID add = (*env)->GetMethodID(env, cls, "add", "(Ljava/lang/Object;)Z");
    jobject list = (*env)->NewObject(env, cls, ctor, count > 0 ? count : 4);
    for (int32_t index = 0; index < count; index++) {
        (*env)->CallBooleanMethod(env, list, add, (jobject)objects[index]);
    }
    (*env)->DeleteLocalRef(env, cls);
    return list;
}

int32_t jni_arraylist_size(void *env_ptr, void *list) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)list);
    jmethodID method = (*env)->GetMethodID(env, cls, "size", "()I");
    jint result = (*env)->CallIntMethod(env, (jobject)list, method);
    (*env)->DeleteLocalRef(env, cls);
    return (int32_t)result;
}

void *jni_arraylist_get(void *env_ptr, void *list, int32_t index) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)list);
    jmethodID method = (*env)->GetMethodID(env, cls, "get", "(I)Ljava/lang/Object;");
    jobject result = (*env)->CallObjectMethod(env, (jobject)list, method, index);
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

void jni_arraylist_add(void *env_ptr, void *list, void *object) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)list);
    jmethodID method = (*env)->GetMethodID(env, cls, "add", "(Ljava/lang/Object;)Z");
    (*env)->CallBooleanMethod(env, (jobject)list, method, (jobject)object);
    (*env)->DeleteLocalRef(env, cls);
}

void *jni_arraylist_remove_at(void *env_ptr, void *list, int32_t index) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)list);
    jmethodID method = (*env)->GetMethodID(env, cls, "remove", "(I)Ljava/lang/Object;");
    jobject result = (*env)->CallObjectMethod(env, (jobject)list, method, index);
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

void jni_arraylist_clear(void *env_ptr, void *list) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)list);
    jmethodID method = (*env)->GetMethodID(env, cls, "clear", "()V");
    (*env)->CallVoidMethod(env, (jobject)list, method);
    (*env)->DeleteLocalRef(env, cls);
}

void jni_viewgroup_add_views_batch(void *env_ptr, void *view_group, void **children, int32_t count) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)view_group);
    jmethodID add_view = (*env)->GetMethodID(env, cls, "addView", "(Landroid/view/View;)V");
    for (int32_t index = 0; index < count; index++) {
        (*env)->CallVoidMethod(env, (jobject)view_group, add_view, (jobject)children[index]);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void jni_viewgroup_remove_all(void *env_ptr, void *view_group) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)view_group);
    jmethodID method = (*env)->GetMethodID(env, cls, "removeAllViews", "()V");
    (*env)->CallVoidMethod(env, (jobject)view_group, method);
    (*env)->DeleteLocalRef(env, cls);
}

void *jni_new_global_ref(void *env_ptr, void *local_ref) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (*env)->NewGlobalRef(env, (jobject)local_ref);
}

void jni_delete_global_ref(void *env_ptr, void *global_ref) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    if (global_ref) {
        (*env)->DeleteGlobalRef(env, (jobject)global_ref);
    }
}

void jni_delete_local_ref(void *env_ptr, void *local_ref) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    if (local_ref) {
        (*env)->DeleteLocalRef(env, (jobject)local_ref);
    }
}

int32_t jni_push_local_frame(void *env_ptr, int32_t capacity) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (int32_t)(*env)->PushLocalFrame(env, capacity);
}

void *jni_pop_local_frame(void *env_ptr, void *result) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (*env)->PopLocalFrame(env, (jobject)result);
}

void *jni_hashmap_create_string_string(void *env_ptr, uint8_t **keys, uint8_t **values, int32_t count) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->FindClass(env, "java/util/HashMap");
    jmethodID ctor = (*env)->GetMethodID(env, cls, "<init>", "()V");
    jmethodID put = (*env)->GetMethodID(env, cls, "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    jobject map = (*env)->NewObject(env, cls, ctor);

    for (int32_t index = 0; index < count; index++) {
        jstring key = ap_new_string(env, keys[index], -1);
        jstring value = ap_new_string(env, values[index], -1);
        (*env)->CallObjectMethod(env, map, put, key, value);
        (*env)->DeleteLocalRef(env, key);
        (*env)->DeleteLocalRef(env, value);
    }

    (*env)->DeleteLocalRef(env, cls);
    return map;
}
