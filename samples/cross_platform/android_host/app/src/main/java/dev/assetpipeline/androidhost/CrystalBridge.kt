package dev.assetpipeline.androidhost

import android.content.Context
import android.view.View

object CrystalBridge {
    private var didLoad = false
    var callbackObserver: (() -> Unit)? = null

    fun initialize() {
        if (didLoad) return
        System.loadLibrary("android_material_host")
        didLoad = true
    }

    @JvmStatic
    fun dispatchVoidCallback(callbackId: Long) {
        dispatchVoidCallbackNative(callbackId)
        callbackObserver?.invoke()
    }

    @JvmStatic
    fun dispatchStringCallback(callbackId: Long, value: String) {
        dispatchStringCallbackNative(callbackId, value)
        callbackObserver?.invoke()
    }

    @JvmStatic
    fun dispatchBoolCallback(callbackId: Long, value: Boolean) {
        dispatchBoolCallbackNative(callbackId, value)
        callbackObserver?.invoke()
    }

    @JvmStatic
    fun dispatchFloatCallback(callbackId: Long, value: Double) {
        dispatchFloatCallbackNative(callbackId, value)
        callbackObserver?.invoke()
    }

    @JvmStatic
    fun dispatchIntCallback(callbackId: Long, value: Int) {
        dispatchIntCallbackNative(callbackId, value)
        callbackObserver?.invoke()
    }

    @JvmStatic
    private external fun dispatchVoidCallbackNative(callbackId: Long)

    @JvmStatic
    private external fun dispatchStringCallbackNative(callbackId: Long, value: String)

    @JvmStatic
    private external fun dispatchBoolCallbackNative(callbackId: Long, value: Boolean)

    @JvmStatic
    private external fun dispatchFloatCallbackNative(callbackId: Long, value: Double)

    @JvmStatic
    private external fun dispatchIntCallbackNative(callbackId: Long, value: Int)

    external fun renderStudy(context: Context, slug: String): View?
}
