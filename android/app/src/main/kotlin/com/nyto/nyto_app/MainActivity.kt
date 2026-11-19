package com.nyto.nyto_app

import android.os.Bundle
import android.os.SystemClock
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var bootCover: ImageView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (bootShownAtMs == 0L) {
            bootShownAtMs = SystemClock.elapsedRealtime()
        }
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawableResource(R.drawable.launch_background)

        val cover = ImageView(this).apply {
            setImageResource(R.drawable.nyto_boot_splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            setBackgroundColor(0xFF05070A.toInt())
        }
        bootCover = cover
        (window.decorView as ViewGroup).addView(
            cover,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BOOT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "logoShownMs") {
                    val start = bootShownAtMs
                    val elapsed =
                        if (start == 0L) 0 else (SystemClock.elapsedRealtime() - start).toInt()
                    result.success(elapsed)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        val cover = bootCover ?: return
        bootCover = null
        cover.post {
            (cover.parent as? ViewGroup)?.removeView(cover)
        }
    }

    companion object {
        private const val BOOT_CHANNEL = "nyto/boot"
        @JvmStatic var bootShownAtMs: Long = 0L
    }
}
