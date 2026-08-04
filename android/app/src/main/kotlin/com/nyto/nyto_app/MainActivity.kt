package com.nyto.nyto_app

import android.os.Bundle
import android.os.SystemClock
import android.view.animation.AccelerateDecelerateInterpolator
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

/**
 * Cold start:
 * 1) System splash shows NYTO wordmark immediately (no blank black)
 * 2) Hold at least 1s after UI is ready
 * 3) Soft-fade splash away → Welcome underneath
 */
class MainActivity : FlutterActivity() {
    @Volatile
    private var keepSplash = true

    private var splashShownAt = 0L
    private var releasePosted = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepSplash }

        // Soft fade out — without this listener, Android removes splash instantly.
        splashScreen.setOnExitAnimationListener { provider ->
            val splashView = provider.view
            splashView.animate()
                .alpha(0f)
                .setDuration(520L)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .withEndAction {
                    provider.remove()
                }
                .start()
        }

        super.onCreate(savedInstanceState)
        splashShownAt = SystemClock.elapsedRealtime()

        // Safety: never stick on splash forever if Flutter UI callback is late.
        window.decorView.postDelayed({ releaseSplash() }, 2500L)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        val elapsed = SystemClock.elapsedRealtime() - splashShownAt
        val remaining = (1000L - elapsed).coerceAtLeast(0L)
        window.decorView.postDelayed({ releaseSplash() }, remaining)
    }

    private fun releaseSplash() {
        if (releasePosted) return
        releasePosted = true
        keepSplash = false
    }
}
