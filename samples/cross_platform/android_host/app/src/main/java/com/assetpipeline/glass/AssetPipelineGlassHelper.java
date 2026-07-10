// Phase 5 — Glass material helper for the Android renderer.
//
// The Crystal-side android_renderer.cr#visit(UI::GlassBackground) resolves
// the material step from tokens and calls into the JNI bridge function
// android_view_apply_glass which dispatches into this static helper.
//
// On API 31+ (Android 12 / S), the helper applies a real RenderEffect
// gaussian blur to the supplied View. On older devices it falls back to
// setBackgroundColor at the supplied fallback ARGB. The Crystal-side code
// observes the return value and, if 0 (no real blur), falls back to a
// setBackgroundColor of its own as a defense in depth.
//
// Empirical verification of the API 31+ blur path is Phase 6.5's audit
// harness deliverable; this file is the production code that harness
// validates.

package com.assetpipeline.glass;

import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.os.Build;
import android.view.View;

public final class AssetPipelineGlassHelper {

    private AssetPipelineGlassHelper() {}

    /**
     * Apply a frosted-glass effect to {@code view}.
     *
     * @param view         the View receiving the effect (typically a
     *                     FrameLayout wrapping the glass content)
     * @param blurRadius   blur kernel radius in device-independent pixels
     * @param fallbackArgb 32-bit ARGB color used as background fill on
     *                     API 30 and below, or if RenderEffect creation
     *                     fails
     * @return true if a real RenderEffect blur was applied; false if the
     *         fallback solid fill was used
     */
    public static boolean applyGlass(View view, float blurRadius, int fallbackArgb) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                RenderEffect effect = RenderEffect.createBlurEffect(
                        blurRadius, blurRadius, Shader.TileMode.CLAMP);
                view.setRenderEffect(effect);
                return true;
            } catch (Throwable t) {
                // Fall through to fallback fill.
            }
        }
        view.setBackgroundColor(fallbackArgb);
        return false;
    }
}
