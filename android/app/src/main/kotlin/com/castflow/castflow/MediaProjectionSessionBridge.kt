package com.castflow.castflow

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
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

    private var pendingResult: MethodChannel.Result? = null
    private var mediaProjection: MediaProjection? = null

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

        val result = pendingResult
        pendingResult = null

        if (result == null) {
            return true
        }

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.error(
                "media_projection_denied",
                "Screen capture permission was not granted.",
                null,
            )
            return true
        }

        return try {
            startForegroundService()
            mediaProjection = projectionManager.getMediaProjection(resultCode, data)
            result.success(null)
            true
        } catch (error: Throwable) {
            stopForegroundService()
            result.error(
                "media_projection_start_failed",
                error.message ?: "Unable to start MediaProjection.",
                null,
            )
            true
        }
    }

    fun dispose() {
        val result = pendingResult
        pendingResult = null
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

    private fun stop() {
        mediaProjection?.stop()
        mediaProjection = null
        stopForegroundService()
    }

    private fun startForegroundService() {
        val intent = Intent(activity, ScreenCaptureForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
    }

    private fun stopForegroundService() {
        val intent = Intent(activity, ScreenCaptureForegroundService::class.java)
        activity.stopService(intent)
    }
}
