package com.castflow.castflow

import android.app.Activity
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ScreenCaptureBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val channelName = "castflow/screen_capture"
    }

    private val methodChannel = MethodChannel(messenger, channelName)

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startForegroundService" -> {
                startForegroundService()
                result.success(null)
            }
            "stopForegroundService" -> {
                stopForegroundService()
                result.success(null)
            }
            else -> result.notImplemented()
        }
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
