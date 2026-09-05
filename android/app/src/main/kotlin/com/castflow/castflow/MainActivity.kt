package com.castflow.castflow

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var wifiDirectBridge: WifiDirectBridge
    private lateinit var screenCaptureBridge: ScreenCaptureBridge
    private lateinit var mediaProjectionSessionBridge: MediaProjectionSessionBridge
    private lateinit var hardwareEncoderBridge: HardwareEncoderBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wifiDirectBridge = WifiDirectBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        screenCaptureBridge = ScreenCaptureBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        mediaProjectionSessionBridge = MediaProjectionSessionBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        hardwareEncoderBridge = HardwareEncoderBridge(
            projectionBridge = mediaProjectionSessionBridge,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        if (
            ::mediaProjectionSessionBridge.isInitialized &&
            mediaProjectionSessionBridge.onActivityResult(requestCode, resultCode, data)
        ) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (::wifiDirectBridge.isInitialized) {
            wifiDirectBridge.onRequestPermissionsResult(
                requestCode = requestCode,
                grantResults = grantResults,
            )
        }
    }

    override fun onDestroy() {
        if (::hardwareEncoderBridge.isInitialized) {
            hardwareEncoderBridge.dispose()
        }
        if (::mediaProjectionSessionBridge.isInitialized) {
            mediaProjectionSessionBridge.dispose()
        }
        super.onDestroy()
    }
}
