package com.atesur.atesur_app_v4

import android.os.Bundle
import com.google.android.gms.cast.framework.CastContext
import io.flutter.embedding.android.FlutterFragmentActivity

import android.content.res.Configuration
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "puntito.simple_pip_mode"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            android.util.Log.d("MainActivity", "Attempting to initialize CastContext...")
            CastContext.getSharedInstance(this)
            android.util.Log.d("MainActivity", "✅ CastContext initialized successfully via MainActivity")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Failed to initialize CastContext: ${e.message}", e)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            val method = if (isInPictureInPictureMode) "onPipEntered" else "onPipExited"
            MethodChannel(messenger, CHANNEL).invokeMethod(method, null)
        }
    }
}
