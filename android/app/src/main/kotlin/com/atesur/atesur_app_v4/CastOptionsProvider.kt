package com.atesur.atesur_app_v4

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions

class CastOptionsProvider : OptionsProvider {
    init {
        android.util.Log.d("CastOptionsProvider", "Initializing CastOptionsProvider...")
    }

    override fun getCastOptions(context: Context): CastOptions {
        android.util.Log.d("CastOptionsProvider", "getCastOptions called")
        return CastOptions.Builder()
            .setReceiverApplicationId("CC1AD845") // Default Media Receiver
            .setCastMediaOptions(
                CastMediaOptions.Builder()
                    .build()
            )
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}
