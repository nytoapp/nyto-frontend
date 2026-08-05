package com.nyto.nyto_app

import android.os.Bundle
import android.os.SystemClock
import android.view.animation.AccelerateDecelerateInterpolator
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

/**
 * Cold start: NYTO wordmark on first tap → hold ~2s → soft fade into Welcome.
 * (No blank black. Flutter SplashScreen is only used on warm re-open.)
 */
class MainActivity : FlutterActivity() {
    @Volatile
    private var keepSplash = true

    private var splashShownAt = 0L
    private var releasePosted = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepSplash }

        splashScreen.setOnExitAnimationListener { provider ->
            val splashView = provider.view
            splashView.animate()
                .alpha(0f)
                .setDuration(600L)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .withEndAction {
                    provider.remove()
                }
                .start()
        }

        super.onCreate(savedInstanceState)
        splashShownAt = SystemClock.elapsedRealtime()

        // Safety cap.
        window.decorView.postDelayed({ releaseSplash() }, 2200L)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        val elapsed = SystemClock.elapsedRealtime() - splashShownAt
        // ~1.4s hold then 600ms soft fade ≈ 2s total.
        val remaining = (1400L - elapsed).coerceAtLeast(0L)
        window.decorView.postDelayed({ releaseSplash() }, remaining)
    }

    private fun releaseSplash() {
        if (releasePosted) return
        releasePosted = true
        keepSplash = false
    }
}
