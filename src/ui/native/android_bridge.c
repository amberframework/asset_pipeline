#include <jni.h>
#include <math.h>
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

static jmethodID ap_get_method(JNIEnv *env, jclass cls, const char *name, const char *sig) {
    return (*env)->GetMethodID(env, cls, name, sig);
}

static jmethodID ap_try_get_method(JNIEnv *env, jclass cls, const char *name, const char *sig) {
    jmethodID method = (*env)->GetMethodID(env, cls, name, sig);
    if (!method && (*env)->ExceptionCheck(env)) {
        (*env)->ExceptionClear(env);
    }
    return method;
}

static jmethodID ap_get_static_method(JNIEnv *env, jclass cls, const char *name, const char *sig) {
    return (*env)->GetStaticMethodID(env, cls, name, sig);
}

static jobject ap_make_color_state_list(JNIEnv *env, jint argb) {
    jclass cls = (*env)->FindClass(env, "android/content/res/ColorStateList");
    if (!cls) {
        return NULL;
    }

    jmethodID value_of = ap_get_static_method(env, cls, "valueOf", "(I)Landroid/content/res/ColorStateList;");
    jobject color_state_list = value_of ? (*env)->CallStaticObjectMethod(env, cls, value_of, argb) : NULL;
    (*env)->DeleteLocalRef(env, cls);
    return color_state_list;
}

static jobject ap_new_callback_helper(JNIEnv *env, const char *class_name, uint64_t callback_id) {
    jclass cls = (*env)->FindClass(env, class_name);
    if (!cls) {
        return NULL;
    }

    jmethodID ctor = ap_get_method(env, cls, "<init>", "(J)V");
    jobject helper = ctor ? (*env)->NewObject(env, cls, ctor, (jlong)callback_id) : NULL;
    (*env)->DeleteLocalRef(env, cls);
    return helper;
}

static jobject ap_new_dual_callback_helper(JNIEnv *env, const char *class_name, uint64_t callback_id_a, uint64_t callback_id_b) {
    jclass cls = (*env)->FindClass(env, class_name);
    if (!cls) {
        return NULL;
    }

    jmethodID ctor = ap_get_method(env, cls, "<init>", "(JJ)V");
    jobject helper = ctor ? (*env)->NewObject(env, cls, ctor, (jlong)callback_id_a, (jlong)callback_id_b) : NULL;
    (*env)->DeleteLocalRef(env, cls);
    return helper;
}

static jobject ap_ensure_gradient_background(JNIEnv *env, jobject view) {
    jclass view_cls = (*env)->GetObjectClass(env, view);
    jmethodID get_background = ap_get_method(env, view_cls, "getBackground", "()Landroid/graphics/drawable/Drawable;");
    jobject background = get_background ? (*env)->CallObjectMethod(env, view, get_background) : NULL;

    jclass gradient_cls = (*env)->FindClass(env, "android/graphics/drawable/GradientDrawable");
    if (background && gradient_cls && (*env)->IsInstanceOf(env, background, gradient_cls)) {
        (*env)->DeleteLocalRef(env, view_cls);
        (*env)->DeleteLocalRef(env, gradient_cls);
        return background;
    }

    if (background) {
        (*env)->DeleteLocalRef(env, background);
    }

    jmethodID ctor = ap_get_method(env, gradient_cls, "<init>", "()V");
    jobject gradient = ctor ? (*env)->NewObject(env, gradient_cls, ctor) : NULL;

    if (gradient) {
        jmethodID set_color = ap_try_get_method(env, gradient_cls, "setColor", "(I)V");
        jmethodID set_shape = ap_try_get_method(env, gradient_cls, "setShape", "(I)V");
        jmethodID set_background = ap_get_method(env, view_cls, "setBackground", "(Landroid/graphics/drawable/Drawable;)V");

        if (set_shape) {
            (*env)->CallVoidMethod(env, gradient, set_shape, 0);
        }
        if (set_color) {
            (*env)->CallVoidMethod(env, gradient, set_color, 0x00000000);
        }
        if (set_background) {
            (*env)->CallVoidMethod(env, view, set_background, gradient);
        }
    }

    (*env)->DeleteLocalRef(env, view_cls);
    (*env)->DeleteLocalRef(env, gradient_cls);
    return gradient;
}

void *android_view_new(void *env_ptr, uint8_t *class_name, void *context) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->FindClass(env, (const char *)class_name);
    if (!cls) {
        return NULL;
    }

    jmethodID ctor = ap_get_method(env, cls, "<init>", "(Landroid/content/Context;)V");
    jobject view = ctor ? (*env)->NewObject(env, cls, ctor, (jobject)context) : NULL;
    (*env)->DeleteLocalRef(env, cls);
    return view;
}

void *android_view_new_themed(void *env_ptr, uint8_t *class_name, void *context, uint8_t *style_field_name) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject themed_context = NULL;

    if (style_field_name && style_field_name[0] != '\0') {
        jclass style_cls = (*env)->FindClass(env, "com/google/android/material/R$style");
        if (style_cls) {
            jfieldID style_field = (*env)->GetStaticFieldID(env, style_cls, (const char *)style_field_name, "I");
            if (!style_field && (*env)->ExceptionCheck(env)) {
                (*env)->ExceptionClear(env);
            }
            if (style_field) {
                jint style_res = (*env)->GetStaticIntField(env, style_cls, style_field);
                if (style_res != 0) {
                    jclass wrapper_cls = (*env)->FindClass(env, "android/view/ContextThemeWrapper");
                    if (wrapper_cls) {
                        jmethodID wrapper_ctor = ap_get_method(env, wrapper_cls, "<init>", "(Landroid/content/Context;I)V");
                        if (wrapper_ctor) {
                            themed_context = (*env)->NewObject(env, wrapper_cls, wrapper_ctor, (jobject)context, style_res);
                        }
                        (*env)->DeleteLocalRef(env, wrapper_cls);
                    }
                }
            }
            (*env)->DeleteLocalRef(env, style_cls);
        }
    }

    jclass cls = (*env)->FindClass(env, (const char *)class_name);
    if (!cls) {
        if (themed_context) {
            (*env)->DeleteLocalRef(env, themed_context);
        }
        return NULL;
    }

    jmethodID ctor = ap_get_method(env, cls, "<init>", "(Landroid/content/Context;)V");
    jobject ctor_context = themed_context ? themed_context : (jobject)context;
    jobject view = ctor ? (*env)->NewObject(env, cls, ctor, ctor_context) : NULL;

    if (themed_context) {
        (*env)->DeleteLocalRef(env, themed_context);
    }
    (*env)->DeleteLocalRef(env, cls);
    return view;
}

void android_textview_set_text(void *env_ptr, void *tv, uint8_t *text, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)tv);
    jmethodID method = ap_get_method(env, cls, "setText", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, text, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)tv, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textview_set_text_size(void *env_ptr, void *tv, float size_sp) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)tv);
    jmethodID method = ap_get_method(env, cls, "setTextSize", "(F)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)tv, method, size_sp);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textview_set_text_color(void *env_ptr, void *tv, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)tv);
    jmethodID method = ap_get_method(env, cls, "setTextColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)tv, method, argb);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textview_set_gravity(void *env_ptr, void *tv, int32_t gravity) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)tv);
    jmethodID method = ap_get_method(env, cls, "setGravity", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)tv, method, gravity);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textview_set_max_lines(void *env_ptr, void *tv, int32_t max) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)tv);
    jmethodID method = ap_get_method(env, cls, "setMaxLines", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)tv, method, max);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textview_set_single_line(void *env_ptr, void *tv, int32_t single) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)tv);
    jmethodID method = ap_get_method(env, cls, "setSingleLine", "(Z)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)tv, method, single ? JNI_TRUE : JNI_FALSE);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textview_set_typeface(void *env_ptr, void *tv, int32_t style) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass text_cls = (*env)->GetObjectClass(env, (jobject)tv);
    jclass typeface_cls = (*env)->FindClass(env, "android/graphics/Typeface");
    jmethodID default_from_style = ap_get_static_method(env, typeface_cls, "defaultFromStyle", "(I)Landroid/graphics/Typeface;");
    jmethodID set_typeface = ap_get_method(env, text_cls, "setTypeface", "(Landroid/graphics/Typeface;)V");
    jobject typeface = default_from_style ? (*env)->CallStaticObjectMethod(env, typeface_cls, default_from_style, style) : NULL;
    if (set_typeface && typeface) {
        (*env)->CallVoidMethod(env, (jobject)tv, set_typeface, typeface);
    }
    if (typeface) {
        (*env)->DeleteLocalRef(env, typeface);
    }
    (*env)->DeleteLocalRef(env, typeface_cls);
    (*env)->DeleteLocalRef(env, text_cls);
}

void android_imageview_set_scale_type(void *env_ptr, void *iv, int32_t scale_type) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass image_cls = (*env)->GetObjectClass(env, (jobject)iv);
    jclass scale_cls = (*env)->FindClass(env, "android/widget/ImageView$ScaleType");
    const char *field_name = "FIT_CENTER";
    if (scale_type == 1) {
        field_name = "CENTER_CROP";
    } else if (scale_type == 2) {
        field_name = "FIT_XY";
    }
    jfieldID field = (*env)->GetStaticFieldID(env, scale_cls, field_name, "Landroid/widget/ImageView$ScaleType;");
    jmethodID method = ap_get_method(env, image_cls, "setScaleType", "(Landroid/widget/ImageView$ScaleType;)V");
    jobject value = field ? (*env)->GetStaticObjectField(env, scale_cls, field) : NULL;
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)iv, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, scale_cls);
    (*env)->DeleteLocalRef(env, image_cls);
}

void android_imageview_set_image_resource(void *env_ptr, void *iv, int32_t res_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)iv);
    jmethodID method = ap_get_method(env, cls, "setImageResource", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)iv, method, res_id);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_imageview_set_image_named(void *env_ptr, void *iv, uint8_t *name) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject image_view = (jobject)iv;
    jclass view_cls = (*env)->GetObjectClass(env, image_view);
    jmethodID get_context = ap_get_method(env, view_cls, "getContext", "()Landroid/content/Context;");
    jobject context = get_context ? (*env)->CallObjectMethod(env, image_view, get_context) : NULL;
    if (!context) {
        (*env)->DeleteLocalRef(env, view_cls);
        return;
    }

    jclass context_cls = (*env)->GetObjectClass(env, context);
    jmethodID get_resources = ap_get_method(env, context_cls, "getResources", "()Landroid/content/res/Resources;");
    jmethodID get_package_name = ap_get_method(env, context_cls, "getPackageName", "()Ljava/lang/String;");
    jobject resources = get_resources ? (*env)->CallObjectMethod(env, context, get_resources) : NULL;
    jstring package_name = get_package_name ? (*env)->CallObjectMethod(env, context, get_package_name) : NULL;
    jclass resources_cls = resources ? (*env)->GetObjectClass(env, resources) : NULL;
    jmethodID get_identifier = resources_cls ? ap_get_method(env, resources_cls, "getIdentifier", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I") : NULL;
    jstring image_name = ap_new_string(env, name, -1);
    jstring drawable_type = (*env)->NewStringUTF(env, "drawable");
    jint res_id = get_identifier ? (*env)->CallIntMethod(env, resources, get_identifier, image_name, drawable_type, package_name) : 0;

    if (res_id != 0) {
        android_imageview_set_image_resource(env_ptr, iv, res_id);
    }

    if (drawable_type) {
        (*env)->DeleteLocalRef(env, drawable_type);
    }
    if (image_name) {
        (*env)->DeleteLocalRef(env, image_name);
    }
    if (resources_cls) {
        (*env)->DeleteLocalRef(env, resources_cls);
    }
    if (resources) {
        (*env)->DeleteLocalRef(env, resources);
    }
    if (package_name) {
        (*env)->DeleteLocalRef(env, package_name);
    }
    (*env)->DeleteLocalRef(env, context_cls);
    (*env)->DeleteLocalRef(env, context);
    (*env)->DeleteLocalRef(env, view_cls);
}

void android_edittext_set_hint(void *env_ptr, void *et, uint8_t *hint, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)et);
    jmethodID method = ap_get_method(env, cls, "setHint", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, hint, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)et, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_searchview_set_query_hint(void *env_ptr, void *sv, uint8_t *hint, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sv);
    jmethodID method = ap_try_get_method(env, cls, "setQueryHint", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, hint, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)sv, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_searchview_set_query(void *env_ptr, void *sv, uint8_t *query, int32_t byte_len, int32_t submit) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sv);
    jmethodID method = ap_try_get_method(env, cls, "setQuery", "(Ljava/lang/CharSequence;Z)V");
    jstring value = ap_new_string(env, query, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)sv, method, value, submit ? JNI_TRUE : JNI_FALSE);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_searchview_set_iconified(void *env_ptr, void *sv, int32_t iconified) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sv);
    jmethodID set_default = ap_try_get_method(env, cls, "setIconifiedByDefault", "(Z)V");
    jmethodID set_iconified = ap_try_get_method(env, cls, "setIconified", "(Z)V");
    jboolean flag = iconified ? JNI_TRUE : JNI_FALSE;
    if (set_default) {
        (*env)->CallVoidMethod(env, (jobject)sv, set_default, flag);
    }
    if (set_iconified) {
        (*env)->CallVoidMethod(env, (jobject)sv, set_iconified, flag);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_spinner_set_prompt(void *env_ptr, void *spinner, uint8_t *prompt, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)spinner);
    jmethodID method = ap_try_get_method(env, cls, "setPrompt", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, prompt, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)spinner, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_spinner_set_selection(void *env_ptr, void *spinner, int32_t selected_index) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)spinner);
    jmethodID method = ap_try_get_method(env, cls, "setSelection", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)spinner, method, selected_index);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_spinner_set_items(void *env_ptr, void *spinner, uint8_t *joined_items, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass spinner_cls = (*env)->GetObjectClass(env, (jobject)spinner);
    jmethodID get_context = ap_try_get_method(env, spinner_cls, "getContext", "()Landroid/content/Context;");
    jobject context = get_context ? (*env)->CallObjectMethod(env, (jobject)spinner, get_context) : NULL;
    if (!context) {
        (*env)->DeleteLocalRef(env, spinner_cls);
        return;
    }

    jclass list_cls = (*env)->FindClass(env, "java/util/ArrayList");
    jmethodID list_ctor = ap_get_method(env, list_cls, "<init>", "(I)V");
    jmethodID list_add = ap_get_method(env, list_cls, "add", "(Ljava/lang/Object;)Z");
    jobject items = (*env)->NewObject(env, list_cls, list_ctor, 4);

    if (joined_items && byte_len > 0) {
        char *buffer = (char *)malloc((size_t)byte_len + 1U);
        if (buffer) {
            memcpy(buffer, joined_items, (size_t)byte_len);
            buffer[byte_len] = '\0';

            char *saveptr = NULL;
            char *token = strtok_r(buffer, "\n", &saveptr);
            while (token) {
                jstring value = ap_new_string(env, (const uint8_t *)token, -1);
                if (value) {
                    (*env)->CallBooleanMethod(env, items, list_add, value);
                    (*env)->DeleteLocalRef(env, value);
                }
                token = strtok_r(NULL, "\n", &saveptr);
            }
            free(buffer);
        }
    }

    jclass layout_cls = (*env)->FindClass(env, "android/R$layout");
    jfieldID simple_item_field = (*env)->GetStaticFieldID(env, layout_cls, "simple_spinner_item", "I");
    jfieldID dropdown_item_field = (*env)->GetStaticFieldID(env, layout_cls, "simple_spinner_dropdown_item", "I");
    jint simple_item_layout = simple_item_field ? (*env)->GetStaticIntField(env, layout_cls, simple_item_field) : 0;
    jint dropdown_item_layout = dropdown_item_field ? (*env)->GetStaticIntField(env, layout_cls, dropdown_item_field) : 0;

    jclass adapter_cls = (*env)->FindClass(env, "android/widget/ArrayAdapter");
    jmethodID adapter_ctor = ap_get_method(env, adapter_cls, "<init>", "(Landroid/content/Context;ILjava/util/List;)V");
    jobject adapter = adapter_ctor ? (*env)->NewObject(env, adapter_cls, adapter_ctor, context, simple_item_layout, items) : NULL;

    if (adapter) {
        jmethodID set_dropdown = ap_try_get_method(env, adapter_cls, "setDropDownViewResource", "(I)V");
        if (set_dropdown) {
            (*env)->CallVoidMethod(env, adapter, set_dropdown, dropdown_item_layout);
        }
        jmethodID set_adapter = ap_try_get_method(env, spinner_cls, "setAdapter", "(Landroid/widget/SpinnerAdapter;)V");
        if (set_adapter) {
            (*env)->CallVoidMethod(env, (jobject)spinner, set_adapter, adapter);
        }
    }

    if (adapter) {
        (*env)->DeleteLocalRef(env, adapter);
    }
    (*env)->DeleteLocalRef(env, adapter_cls);
    (*env)->DeleteLocalRef(env, layout_cls);
    (*env)->DeleteLocalRef(env, items);
    (*env)->DeleteLocalRef(env, list_cls);
    (*env)->DeleteLocalRef(env, context);
    (*env)->DeleteLocalRef(env, spinner_cls);
}

void android_edittext_set_input_type(void *env_ptr, void *et, int32_t input_type) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)et);
    jmethodID method = ap_get_method(env, cls, "setInputType", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)et, method, input_type);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_edittext_set_text(void *env_ptr, void *et, uint8_t *text, int32_t byte_len) {
    android_textview_set_text(env_ptr, et, text, byte_len);
}

void *android_edittext_get_text(void *env_ptr, void *et) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)et);
    jmethodID get_text = ap_get_method(env, cls, "getText", "()Landroid/text/Editable;");
    jobject editable = get_text ? (*env)->CallObjectMethod(env, (jobject)et, get_text) : NULL;
    jstring result = NULL;
    if (editable) {
        jclass editable_cls = (*env)->GetObjectClass(env, editable);
        jmethodID to_string = ap_get_method(env, editable_cls, "toString", "()Ljava/lang/String;");
        result = to_string ? (*env)->CallObjectMethod(env, editable, to_string) : NULL;
        (*env)->DeleteLocalRef(env, editable_cls);
        (*env)->DeleteLocalRef(env, editable);
    }
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

void android_textinputlayout_set_hint(void *env_ptr, void *til, uint8_t *hint, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setHint", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, hint, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)til, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_placeholder_text(void *env_ptr, void *til, uint8_t *text, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setPlaceholderText", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, text, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)til, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_helper_text(void *env_ptr, void *til, uint8_t *text, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setHelperText", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, text, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)til, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_box_background_mode(void *env_ptr, void *til, int32_t mode) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setBoxBackgroundMode", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)til, method, mode);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_box_background_color(void *env_ptr, void *til, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setBoxBackgroundColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)til, method, argb);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_box_stroke_color(void *env_ptr, void *til, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setBoxStrokeColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)til, method, argb);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_hint_text_color(void *env_ptr, void *til, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setHintTextColor", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)til, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_textinputlayout_set_end_icon_mode(void *env_ptr, void *til, int32_t mode) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)til);
    jmethodID method = ap_try_get_method(env, cls, "setEndIconMode", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)til, method, mode);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_webview_load_url(void *env_ptr, void *web, uint8_t *url, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)web);
    jmethodID load_url = ap_get_method(env, cls, "loadUrl", "(Ljava/lang/String;)V");
    jstring url_value = ap_new_string(env, url, byte_len);
    if (load_url && url_value) {
        (*env)->CallVoidMethod(env, (jobject)web, load_url, url_value);
    }
    if (url_value) {
        (*env)->DeleteLocalRef(env, url_value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_webview_load_html(void *env_ptr, void *web, uint8_t *html, int32_t html_len,
                               uint8_t *base_url, int32_t base_url_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass web_cls = (*env)->GetObjectClass(env, (jobject)web);
    jmethodID get_settings = ap_try_get_method(env, web_cls, "getSettings", "()Landroid/webkit/WebSettings;");
    jobject settings = get_settings ? (*env)->CallObjectMethod(env, (jobject)web, get_settings) : NULL;

    if (settings) {
        jclass settings_cls = (*env)->GetObjectClass(env, settings);
        jmethodID set_js_enabled = ap_try_get_method(env, settings_cls, "setJavaScriptEnabled", "(Z)V");
        if (set_js_enabled) {
            (*env)->CallVoidMethod(env, settings, set_js_enabled, JNI_TRUE);
        }
        (*env)->DeleteLocalRef(env, settings_cls);
        (*env)->DeleteLocalRef(env, settings);
    }

    jmethodID load_html = ap_get_method(
        env,
        web_cls,
        "loadDataWithBaseURL",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    );
    jstring base_value = ap_new_string(env, base_url, base_url_len);
    jstring html_value = ap_new_string(env, html, html_len);
    jstring mime_type = (*env)->NewStringUTF(env, "text/html");
    jstring encoding = (*env)->NewStringUTF(env, "utf-8");
    if (load_html && html_value && mime_type && encoding) {
        (*env)->CallVoidMethod(env, (jobject)web, load_html, base_value, html_value, mime_type, encoding, NULL);
    }
    if (encoding) {
        (*env)->DeleteLocalRef(env, encoding);
    }
    if (mime_type) {
        (*env)->DeleteLocalRef(env, mime_type);
    }
    if (html_value) {
        (*env)->DeleteLocalRef(env, html_value);
    }
    if (base_value) {
        (*env)->DeleteLocalRef(env, base_value);
    }
    (*env)->DeleteLocalRef(env, web_cls);
}

void android_linearlayout_set_orientation(void *env_ptr, void *ll, int32_t orientation) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)ll);
    jmethodID method = ap_get_method(env, cls, "setOrientation", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)ll, method, orientation);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_linearlayout_set_gravity(void *env_ptr, void *ll, int32_t gravity) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)ll);
    jmethodID method = ap_get_method(env, cls, "setGravity", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)ll, method, gravity);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_viewgroup_add_view(void *env_ptr, void *parent, void *child) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)parent);
    jmethodID method = ap_get_method(env, cls, "addView", "(Landroid/view/View;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)parent, method, (jobject)child);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_viewgroup_add_view_wh(void *env_ptr, void *parent, void *child, int32_t width, int32_t height) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)parent);
    jmethodID method = ap_try_get_method(env, cls, "addView", "(Landroid/view/View;II)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)parent, method, (jobject)child, width, height);
    } else {
        android_viewgroup_add_view(env_ptr, parent, child);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_linearlayout_add_view_weight(void *env_ptr, void *parent, void *child,
                                          int32_t width, int32_t height, float weight) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass params_cls = (*env)->FindClass(env, "android/widget/LinearLayout$LayoutParams");
    jmethodID ctor = ap_get_method(env, params_cls, "<init>", "(IIF)V");
    jobject params = ctor ? (*env)->NewObject(env, params_cls, ctor, width, height, weight) : NULL;

    jclass parent_cls = (*env)->GetObjectClass(env, (jobject)parent);
    jmethodID add_view = ap_get_method(env, parent_cls, "addView", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V");
    if (add_view && params) {
        (*env)->CallVoidMethod(env, (jobject)parent, add_view, (jobject)child, params);
    } else {
        android_viewgroup_add_view(env_ptr, parent, child);
    }

    if (params) {
        (*env)->DeleteLocalRef(env, params);
    }
    (*env)->DeleteLocalRef(env, parent_cls);
    (*env)->DeleteLocalRef(env, params_cls);
}

void android_viewgroup_remove_all(void *env_ptr, void *parent) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)parent);
    jmethodID method = ap_get_method(env, cls, "removeAllViews", "()V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)parent, method);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_visibility(void *env_ptr, void *v, int32_t visibility) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_get_method(env, cls, "setVisibility", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, visibility);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_enabled(void *env_ptr, void *v, int32_t enabled) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setEnabled", "(Z)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, enabled ? JNI_TRUE : JNI_FALSE);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_alpha(void *env_ptr, void *v, float alpha) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_get_method(env, cls, "setAlpha", "(F)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, alpha);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_background_color(void *env_ptr, void *v, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject drawable = ap_ensure_gradient_background(env, (jobject)v);
    if (!drawable) {
        return;
    }

    jclass gradient_cls = (*env)->GetObjectClass(env, drawable);
    jmethodID method = ap_try_get_method(env, gradient_cls, "setColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, drawable, method, argb);
    }
    (*env)->DeleteLocalRef(env, gradient_cls);
    (*env)->DeleteLocalRef(env, drawable);
}

void android_view_clear_background(void *env_ptr, void *v) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setBackground", "(Landroid/graphics/drawable/Drawable;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, NULL);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_content_description(void *env_ptr, void *v, uint8_t *desc, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_get_method(env, cls, "setContentDescription", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, desc, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)v, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_clip_to_outline(void *env_ptr, void *v, int32_t clip) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setClipToOutline", "(Z)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, clip ? JNI_TRUE : JNI_FALSE);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_elevation(void *env_ptr, void *v, float dp) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setElevation", "(F)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, dp);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_padding(void *env_ptr, void *v, int32_t left, int32_t top, int32_t right, int32_t bottom) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_get_method(env, cls, "setPadding", "(IIII)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, left, top, right, bottom);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_clear_focus(void *env_ptr, void *v) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "clearFocus", "()V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_view_set_corner_radius(void *env_ptr, void *v, float radius) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject drawable = ap_ensure_gradient_background(env, (jobject)v);
    if (!drawable) {
        return;
    }

    jclass gradient_cls = (*env)->GetObjectClass(env, drawable);
    jmethodID method = ap_try_get_method(env, gradient_cls, "setCornerRadius", "(F)V");
    if (method) {
        (*env)->CallVoidMethod(env, drawable, method, radius);
    }
    (*env)->DeleteLocalRef(env, gradient_cls);
    (*env)->DeleteLocalRef(env, drawable);
}

void android_view_set_stroke(void *env_ptr, void *v, float width, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject drawable = ap_ensure_gradient_background(env, (jobject)v);
    if (!drawable) {
        return;
    }

    jclass gradient_cls = (*env)->GetObjectClass(env, drawable);
    jmethodID method = ap_try_get_method(env, gradient_cls, "setStroke", "(II)V");
    if (method) {
        (*env)->CallVoidMethod(env, drawable, method, (jint)lroundf(width), argb);
    }
    (*env)->DeleteLocalRef(env, gradient_cls);
    (*env)->DeleteLocalRef(env, drawable);
}

void android_material_button_set_background_tint(void *env_ptr, void *btn, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)btn);
    jmethodID method = ap_try_get_method(env, cls, "setBackgroundTintList", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)btn, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_button_set_stroke_color(void *env_ptr, void *btn, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)btn);
    jmethodID method = ap_try_get_method(env, cls, "setStrokeColor", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)btn, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_button_set_stroke_width(void *env_ptr, void *btn, int32_t width) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)btn);
    jmethodID method = ap_try_get_method(env, cls, "setStrokeWidth", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)btn, method, width);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_button_set_corner_radius(void *env_ptr, void *btn, int32_t radius) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)btn);
    jmethodID method = ap_try_get_method(env, cls, "setCornerRadius", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)btn, method, radius);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_card_set_background_color(void *env_ptr, void *card, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)card);
    jmethodID method = ap_try_get_method(env, cls, "setCardBackgroundColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)card, method, argb);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_card_set_radius(void *env_ptr, void *card, float radius) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)card);
    jmethodID method = ap_try_get_method(env, cls, "setRadius", "(F)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)card, method, radius);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_card_set_elevation(void *env_ptr, void *card, float elevation) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)card);
    jmethodID method = ap_try_get_method(env, cls, "setCardElevation", "(F)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)card, method, elevation);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_card_set_stroke_color(void *env_ptr, void *card, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)card);
    jmethodID method = ap_try_get_method(env, cls, "setStrokeColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)card, method, argb);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_material_card_set_stroke_width(void *env_ptr, void *card, int32_t width) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)card);
    jmethodID method = ap_try_get_method(env, cls, "setStrokeWidth", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)card, method, width);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_toolbar_set_title(void *env_ptr, void *toolbar, uint8_t *title, int32_t byte_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)toolbar);
    jmethodID method = ap_try_get_method(env, cls, "setTitle", "(Ljava/lang/CharSequence;)V");
    jstring value = ap_new_string(env, title, byte_len);
    if (method && value) {
        (*env)->CallVoidMethod(env, (jobject)toolbar, method, value);
    }
    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_toolbar_set_title_text_color(void *env_ptr, void *toolbar, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)toolbar);
    jmethodID method = ap_try_get_method(env, cls, "setTitleTextColor", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)toolbar, method, argb);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_toolbar_add_menu_item(void *env_ptr, void *toolbar, int32_t item_id,
                                   uint8_t *title, int32_t byte_len, int32_t show_as_action) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass toolbar_cls = (*env)->GetObjectClass(env, (jobject)toolbar);
    jmethodID get_menu = ap_try_get_method(env, toolbar_cls, "getMenu", "()Landroid/view/Menu;");
    jobject menu = get_menu ? (*env)->CallObjectMethod(env, (jobject)toolbar, get_menu) : NULL;
    if (!menu) {
        (*env)->DeleteLocalRef(env, toolbar_cls);
        return;
    }

    jclass menu_cls = (*env)->GetObjectClass(env, menu);
    jmethodID add = ap_try_get_method(env, menu_cls, "add", "(IIILjava/lang/CharSequence;)Landroid/view/MenuItem;");
    jstring value = ap_new_string(env, title, byte_len);
    jobject menu_item = (add && value) ? (*env)->CallObjectMethod(env, menu, add, 0, item_id, 0, value) : NULL;
    if (menu_item) {
        jclass item_cls = (*env)->GetObjectClass(env, menu_item);
        jmethodID set_show = ap_try_get_method(env, item_cls, "setShowAsAction", "(I)V");
        if (set_show) {
            (*env)->CallVoidMethod(env, menu_item, set_show, show_as_action);
        }
        (*env)->DeleteLocalRef(env, item_cls);
        (*env)->DeleteLocalRef(env, menu_item);
    }

    if (value) {
        (*env)->DeleteLocalRef(env, value);
    }
    (*env)->DeleteLocalRef(env, menu_cls);
    (*env)->DeleteLocalRef(env, menu);
    (*env)->DeleteLocalRef(env, toolbar_cls);
}

void android_context_start_share_chooser(void *env_ptr, void *context_ptr,
                                         uint8_t *title, int32_t title_len,
                                         uint8_t *text, int32_t text_len,
                                         uint8_t *url, int32_t url_len,
                                         uint8_t *subject, int32_t subject_len) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject context = (jobject)context_ptr;
    if (!context) {
        return;
    }

    size_t share_len = 0U;
    if (text && text_len > 0) {
        share_len += (size_t)text_len;
    }
    if (url && url_len > 0) {
        if (share_len > 0U) {
            share_len += 1U;
        }
        share_len += (size_t)url_len;
    }
    if (share_len == 0U) {
        return;
    }

    char *share_buffer = (char *)malloc(share_len + 1U);
    if (!share_buffer) {
        return;
    }

    size_t cursor = 0U;
    if (text && text_len > 0) {
        memcpy(share_buffer + cursor, text, (size_t)text_len);
        cursor += (size_t)text_len;
    }
    if (url && url_len > 0) {
        if (cursor > 0U) {
            share_buffer[cursor++] = '\n';
        }
        memcpy(share_buffer + cursor, url, (size_t)url_len);
        cursor += (size_t)url_len;
    }
    share_buffer[cursor] = '\0';

    jclass intent_cls = (*env)->FindClass(env, "android/content/Intent");
    jmethodID intent_ctor = ap_get_method(env, intent_cls, "<init>", "()V");
    jobject intent = intent_ctor ? (*env)->NewObject(env, intent_cls, intent_ctor) : NULL;
    if (!intent) {
        free(share_buffer);
        (*env)->DeleteLocalRef(env, intent_cls);
        return;
    }

    jmethodID set_action = ap_try_get_method(env, intent_cls, "setAction", "(Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID set_type = ap_try_get_method(env, intent_cls, "setType", "(Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID put_extra = ap_try_get_method(env, intent_cls, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;");
    jmethodID add_flags = ap_try_get_method(env, intent_cls, "addFlags", "(I)Landroid/content/Intent;");
    jmethodID create_chooser = ap_get_static_method(env, intent_cls, "createChooser", "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;");

    jfieldID action_send_field = (*env)->GetStaticFieldID(env, intent_cls, "ACTION_SEND", "Ljava/lang/String;");
    jfieldID extra_text_field = (*env)->GetStaticFieldID(env, intent_cls, "EXTRA_TEXT", "Ljava/lang/String;");
    jfieldID extra_subject_field = (*env)->GetStaticFieldID(env, intent_cls, "EXTRA_SUBJECT", "Ljava/lang/String;");
    jfieldID new_task_field = (*env)->GetStaticFieldID(env, intent_cls, "FLAG_ACTIVITY_NEW_TASK", "I");

    jobject action_send = action_send_field ? (*env)->GetStaticObjectField(env, intent_cls, action_send_field) : NULL;
    jobject extra_text = extra_text_field ? (*env)->GetStaticObjectField(env, intent_cls, extra_text_field) : NULL;
    jobject extra_subject = extra_subject_field ? (*env)->GetStaticObjectField(env, intent_cls, extra_subject_field) : NULL;
    jint flag_new_task = new_task_field ? (*env)->GetStaticIntField(env, intent_cls, new_task_field) : 0;

    jstring mime_type = ap_new_string(env, (const uint8_t *)"text/plain", -1);
    jstring share_body = ap_new_string(env, (const uint8_t *)share_buffer, (jint)cursor);
    jstring chooser_title = ap_new_string(env, title, title_len);
    jstring subject_value = ap_new_string(env, subject, subject_len);

    if (set_action && action_send) {
        (*env)->CallObjectMethod(env, intent, set_action, action_send);
    }
    if (set_type && mime_type) {
        (*env)->CallObjectMethod(env, intent, set_type, mime_type);
    }
    if (put_extra && extra_text && share_body) {
        (*env)->CallObjectMethod(env, intent, put_extra, extra_text, share_body);
    }
    if (put_extra && extra_subject && subject_value) {
        (*env)->CallObjectMethod(env, intent, put_extra, extra_subject, subject_value);
    }
    if (add_flags && flag_new_task != 0) {
        (*env)->CallObjectMethod(env, intent, add_flags, flag_new_task);
    }

    jobject chooser = create_chooser ? (*env)->CallStaticObjectMethod(env, intent_cls, create_chooser, intent, chooser_title) : NULL;
    if (chooser) {
        jclass context_cls = (*env)->GetObjectClass(env, context);
        jmethodID start_activity = ap_try_get_method(env, context_cls, "startActivity", "(Landroid/content/Intent;)V");
        if (start_activity) {
            (*env)->CallVoidMethod(env, context, start_activity, chooser);
        }
        (*env)->DeleteLocalRef(env, context_cls);
        (*env)->DeleteLocalRef(env, chooser);
    }

    if (subject_value) {
        (*env)->DeleteLocalRef(env, subject_value);
    }
    if (chooser_title) {
        (*env)->DeleteLocalRef(env, chooser_title);
    }
    if (share_body) {
        (*env)->DeleteLocalRef(env, share_body);
    }
    if (mime_type) {
        (*env)->DeleteLocalRef(env, mime_type);
    }
    if (extra_subject) {
        (*env)->DeleteLocalRef(env, extra_subject);
    }
    if (extra_text) {
        (*env)->DeleteLocalRef(env, extra_text);
    }
    if (action_send) {
        (*env)->DeleteLocalRef(env, action_send);
    }
    (*env)->DeleteLocalRef(env, intent);
    (*env)->DeleteLocalRef(env, intent_cls);
    free(share_buffer);
}

void android_switch_set_checked(void *env_ptr, void *sw, int32_t checked) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sw);
    jmethodID method = ap_get_method(env, cls, "setChecked", "(Z)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)sw, method, checked ? JNI_TRUE : JNI_FALSE);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_switch_set_thumb_tint(void *env_ptr, void *sw, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)sw);
    jmethodID method = ap_try_get_method(env, cls, "setThumbTintList", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)sw, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_switch_set_track_tint(void *env_ptr, void *sw, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)sw);
    jmethodID method = ap_try_get_method(env, cls, "setTrackTintList", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)sw, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_checkbox_set_checked(void *env_ptr, void *cb, int32_t checked) {
    android_switch_set_checked(env_ptr, cb, checked);
}

void android_checkbox_set_text(void *env_ptr, void *cb, uint8_t *text, int32_t byte_len) {
    android_textview_set_text(env_ptr, cb, text, byte_len);
}

void android_checkbox_set_button_tint(void *env_ptr, void *cb, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)cb);
    jmethodID method = ap_try_get_method(env, cls, "setButtonTintList", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)cb, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_radiogroup_check(void *env_ptr, void *rg, int32_t child_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)rg);
    jmethodID method = ap_get_method(env, cls, "check", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)rg, method, child_id);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_radiobutton_set_text(void *env_ptr, void *rb, uint8_t *text, int32_t byte_len) {
    android_textview_set_text(env_ptr, rb, text, byte_len);
}

void android_radiobutton_set_checked(void *env_ptr, void *rb, int32_t checked) {
    android_switch_set_checked(env_ptr, rb, checked);
}

int32_t android_view_generate_id(void *env_ptr) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->FindClass(env, "android/view/View");
    jmethodID method = ap_get_static_method(env, cls, "generateViewId", "()I");
    jint result = method ? (*env)->CallStaticIntMethod(env, cls, method) : 0;
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

void android_view_set_id(void *env_ptr, void *v, int32_t view_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setId", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, view_id);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_seekbar_set_max(void *env_ptr, void *sb, int32_t max) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sb);
    jmethodID method = ap_get_method(env, cls, "setMax", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)sb, method, max);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_seekbar_set_progress(void *env_ptr, void *sb, int32_t progress) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sb);
    jmethodID method = ap_get_method(env, cls, "setProgress", "(I)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)sb, method, progress);
    }
    (*env)->DeleteLocalRef(env, cls);
}

void android_seekbar_set_progress_tint(void *env_ptr, void *sb, int32_t argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject tint = ap_make_color_state_list(env, argb);
    jclass cls = (*env)->GetObjectClass(env, (jobject)sb);
    jmethodID method = ap_try_get_method(env, cls, "setProgressTintList", "(Landroid/content/res/ColorStateList;)V");
    if (method && tint) {
        (*env)->CallVoidMethod(env, (jobject)sb, method, tint);
    }
    if (tint) {
        (*env)->DeleteLocalRef(env, tint);
    }
    (*env)->DeleteLocalRef(env, cls);
}

int32_t android_seekbar_get_progress(void *env_ptr, void *sb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)sb);
    jmethodID method = ap_get_method(env, cls, "getProgress", "()I");
    jint result = method ? (*env)->CallIntMethod(env, (jobject)sb, method) : 0;
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

int32_t android_compoundbutton_is_checked(void *env_ptr, void *button) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)button);
    jmethodID method = ap_try_get_method(env, cls, "isChecked", "()Z");
    jint result = method ? ((*env)->CallBooleanMethod(env, (jobject)button, method) ? 1 : 0) : 0;
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

int32_t android_radiogroup_get_checked_radio_button_id(void *env_ptr, void *rg) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass cls = (*env)->GetObjectClass(env, (jobject)rg);
    jmethodID method = ap_try_get_method(env, cls, "getCheckedRadioButtonId", "()I");
    jint result = method ? (*env)->CallIntMethod(env, (jobject)rg, method) : -1;
    (*env)->DeleteLocalRef(env, cls);
    return result;
}

void android_view_set_on_click_listener(void *env_ptr, void *v, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalClickListener", callback_id);
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setOnClickListener", "(Landroid/view/View$OnClickListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void android_view_set_on_checked_change_listener(void *env_ptr, void *v, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalCheckedChangeListener", callback_id);
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)v);
    jmethodID method = ap_try_get_method(env, cls, "setOnCheckedChangeListener", "(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)v, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void android_seekbar_set_on_change_listener(void *env_ptr, void *sb, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalSeekBarChangeListener", callback_id);
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)sb);
    jmethodID method = ap_try_get_method(env, cls, "setOnSeekBarChangeListener", "(Landroid/widget/SeekBar$OnSeekBarChangeListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)sb, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void android_edittext_set_text_watcher(void *env_ptr, void *et, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject watcher = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalTextWatcher", callback_id);
    if (!watcher) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)et);
    jmethodID method = ap_try_get_method(env, cls, "addTextChangedListener", "(Landroid/text/TextWatcher;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)et, method, watcher);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, watcher);
}

void android_radiogroup_set_on_checked_change_listener(void *env_ptr, void *rg, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalRadioGroupCheckedChangeListener", callback_id);
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)rg);
    jmethodID method = ap_try_get_method(env, cls, "setOnCheckedChangeListener", "(Landroid/widget/RadioGroup$OnCheckedChangeListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)rg, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void android_searchview_set_on_query_text_listener(void *env_ptr, void *sv, uint64_t change_callback_id, uint64_t submit_callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_dual_callback_helper(
        env,
        "dev/assetpipeline/androidhost/CrystalSearchQueryListener",
        change_callback_id,
        submit_callback_id
    );
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)sv);
    jmethodID method = ap_try_get_method(env, cls, "setOnQueryTextListener", "(Landroid/widget/SearchView$OnQueryTextListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)sv, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void android_searchview_set_on_close_listener(void *env_ptr, void *sv, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalSearchCloseListener", callback_id);
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)sv);
    jmethodID method = ap_try_get_method(env, cls, "setOnCloseListener", "(Landroid/widget/SearchView$OnCloseListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)sv, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void android_spinner_set_on_item_selected_listener(void *env_ptr, void *spinner, uint64_t callback_id) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jobject listener = ap_new_callback_helper(env, "dev/assetpipeline/androidhost/CrystalItemSelectedListener", callback_id);
    if (!listener) {
        return;
    }

    jclass cls = (*env)->GetObjectClass(env, (jobject)spinner);
    jmethodID method = ap_try_get_method(env, cls, "setOnItemSelectedListener", "(Landroid/widget/AdapterView$OnItemSelectedListener;)V");
    if (method) {
        (*env)->CallVoidMethod(env, (jobject)spinner, method, listener);
    }
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, listener);
}

void *android_new_global_ref(void *env_ptr, void *local_ref) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    return (*env)->NewGlobalRef(env, (jobject)local_ref);
}

void android_delete_global_ref(void *env_ptr, void *global_ref) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    if (global_ref) {
        (*env)->DeleteGlobalRef(env, (jobject)global_ref);
    }
}

// Phase 5 — Glass material RenderEffect bridge.
//
// Calls the host's AssetPipelineGlassHelper.applyGlass(view, blurRadius,
// fallbackArgb) static helper. The helper itself decides API 31+ blur vs
// alpha fill — Crystal-side resolution remains uniform. Returns 1 if a
// real RenderEffect blur was applied, 0 if the fallback alpha was used or
// the helper class could not be loaded (e.g., the consumer app did not
// bundle the helper).
int32_t android_view_apply_glass(void *env_ptr, void *view, float blur_radius, int32_t fallback_argb) {
    JNIEnv *env = (JNIEnv *)env_ptr;
    jclass helper_cls = (*env)->FindClass(env, "com/assetpipeline/glass/AssetPipelineGlassHelper");
    if (!helper_cls) {
        if ((*env)->ExceptionCheck(env)) {
            (*env)->ExceptionClear(env);
        }
        return 0;
    }
    jmethodID apply = ap_get_static_method(env, helper_cls, "applyGlass", "(Landroid/view/View;FI)Z");
    if (!apply) {
        (*env)->DeleteLocalRef(env, helper_cls);
        return 0;
    }
    jboolean result = (*env)->CallStaticBooleanMethod(env, helper_cls, apply,
                                                     (jobject)view,
                                                     (jfloat)blur_radius,
                                                     (jint)fallback_argb);
    (*env)->DeleteLocalRef(env, helper_cls);
    return result ? 1 : 0;
}
