package com.castflow.castflow

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaProjectionSessionBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val channelName = "castflow/media_projection"
        private const val requestCode = 7341
    }

    private val methodChannel = MethodChannel(messenger, channelName)
    private val projectionManager =
        activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pendingResult: MethodChannel.Result? = null
    private var pendingConsentResultCode: Int? = null
    private var pendingConsentData: Intent? = null
    private var mediaProjection: MediaProjection? = null

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            mediaProjection = null
            stopForegroundService()
        }
    }

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestAndStart" -> requestAndStart(result)
            "stop" -> {
                stop()
                result.success(null)
            }
            "isActive" -> result.success(mediaProjection != null)
            "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != Companion.requestCode) {
            return false
        }

        if (resultCode != Activity.RESULT_OK || data == null) {
            val result = pendingResult
            clearPendingConsent()
            result?.error(
                "media_projection_denied",
                "Screen capture permission was not granted.",
                null,
            )
            return true
        }

        pendingConsentResultCode = resultCode
        pendingConsentData = data
        startForegroundServiceAndWait()
        return true
    }

    fun activeProjection(): MediaProjection? = mediaProjection

    fun densityDpi(): Int = activity.resources.displayMetrics.densityDpi

    fun dispose() {
        val result = pendingResult
        clearPendingConsent()
        result?.error(
            "activity_disposed",
            "MediaProjection request was interrupted.",
            null,
        )
        stop()
        methodChannel.setMethodCallHandler(null)
    }

    private fun requestAndStart(result: MethodChannel.Result) {
        if (mediaProjection != null) {
            result.success(null)
            return
        }

        if (pendingResult != null) {
            result.error(
                "request_in_progress",
                "A MediaProjection permission request is already active.",
                null,
            )
            return
        }

        pendingResult = result
        activity.startActivityForResult(
            projectionManager.createScreenCaptureIntent(),
            requestCode,
        )
    }

    private fun startForegroundServiceAndWait() {
        val receiver = object : ResultReceiver(mainHandler) {
            override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                if (resultCode != ScreenCaptureForegroundService.readyResultCode) {
                    failStart("Screen capture foreground service failed to become ready.")
                    return
                }
                createProjectionAfterForegroundReady()
            }
        }

        val intent = Intent(activity, ScreenCaptureForegroundService::class.java).apply {
            putExtra(ScreenCaptureForegroundService.extraReadyReceiver, receiver)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
    }

    private fun createProjectionAfterForegroundReady() {
        val result = pendingResult
        val resultCode = pendingConsentResultCode
        val data = pendingConsentData

        if (result == null || resultCode == null || data == null) {
            failStart("MediaProjection consent state was lost.")
            return
        }

        try {
            val projection = projectionManager.getMediaProjection(resultCode, data)
                ?: throw IllegalStateException("MediaProjectionManager returned no session.")
            projection.registerCallback(projectionCallback, mainHandler)
            mediaProjection = projection
            clearPendingConsent(keepResult = false)
            result.success(null)
        } catch (error: Throwable) {
            failStart(error.message ?: "Unable to start MediaProjection.")
        }
    }

    private fun failStart(message: String) {
        val result = pendingResult
        clearPendingConsent()
        stopForegroundService()
        result?.error("media_projection_start_failed", message, null)
    }

    private fun clearPendingConsent(keepResult: Boolean = false) {
        if (!keepResult) {
            pendingResult = null
        }
        pendingConsentResultCode = null
        pendingConsentData = null
    }

    private fun stop() {
        mediaProjection?.unregisterCallback(projectionCallback)
        mediaProjection?.stop()
        mediaProjection = null
        stopForegroundService()
    }

    private fun stopForegroundService() {
        val intent = Intent(activity, ScreenCaptureForegroundService::class.java)
        activity.stopService(intent)
    }
}
