package com.nyto.nyto_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.widget.ImageView

/**
 * Draws the full NYTO screen before Flutter starts, so Android's centered
 * launch icon never becomes its own screen.
 */
class BootActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (MainActivity.bootShownAtMs == 0L) {
            MainActivity.bootShownAtMs = SystemClock.elapsedRealtime()
        }
        window.setBackgroundDrawableResource(R.drawable.launch_background)
        setContentView(
            ImageView(this).apply {
                setImageResource(R.drawable.nyto_boot_splash)
                scaleType = ImageView.ScaleType.CENTER_CROP
            },
        )
        window.decorView.post {
            if (isFinishing) return@post
            startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION),
            )
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
    }
}
