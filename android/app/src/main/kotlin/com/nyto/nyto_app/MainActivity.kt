package com.nyto.nyto_app

import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Same Image 2 look (CENTER_CROP boot art) until Welcome video is ready,
 * then soft-fades out.
 */
class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var cover: View? = null
    private var fading = false

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setBackgroundDrawableResource(R.drawable.launch_background)
        super.onCreate(savedInstanceState)
        attachCover()
        handler.postDelayed({ fadeOutCover() }, 5000L)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nyto/boot")
            .setMethodCallHandler { call, result ->
                if (call.method == "dropBridge") {
                    fadeOutCover()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun attachCover() {
        val decor = window.decorView as? ViewGroup ?: return
        if (cover != null) return
        val iv = ImageView(this).apply {
            setImageResource(R.drawable.nyto_boot_splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            setBackgroundColor(Color.parseColor("#05070A"))
            elevation = 100_000f
            translationZ = 100_000f
            isClickable = true
            fitsSystemWindows = false
        }
        decor.addView(
            iv,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        cover = iv
    }

    private fun fadeOutCover() {
        if (fading) return
        fading = true
        handler.removeCallbacksAndMessages(null)
        val v = cover ?: return
        cover = null
        v.animate()
            .alpha(0f)
            .setDuration(480L)
            .withEndAction {
                (v.parent as? ViewGroup)?.removeView(v)
            }
            .start()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
