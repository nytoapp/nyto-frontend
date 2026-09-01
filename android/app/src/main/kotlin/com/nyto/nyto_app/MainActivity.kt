package com.nyto.nyto_app

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var cover: View? = null

    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { false }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { provider -> provider.remove() }
        }
        window.setBackgroundDrawableResource(R.drawable.nyto_boot_splash)
        ensureCover()
        super.onCreate(savedInstanceState)
        bringCoverToFront()
        handler.postDelayed({ releaseSplash() }, 10000L)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nyto/boot")
            .setMethodCallHandler { call, result ->
                if (call.method == "dropBridge") {
                    releaseSplash()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun ensureCover() {
        if (cover != null) return
        val iv = ImageView(this).apply {
            setImageResource(R.drawable.nyto_boot_splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            setBackgroundColor(Color.parseColor("#05070A"))
        }
        window.addContentView(
            iv,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        cover = iv
    }

    private fun bringCoverToFront() {
        cover?.bringToFront()
        (cover?.parent as? ViewGroup)?.bringChildToFront(cover)
    }

    private fun releaseSplash() {
        handler.removeCallbacksAndMessages(null)
        val v = cover ?: return
        cover = null
        (v.parent as? ViewGroup)?.removeView(v)
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
