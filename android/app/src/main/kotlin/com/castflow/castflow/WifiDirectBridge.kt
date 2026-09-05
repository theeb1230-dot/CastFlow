package com.castflow.castflow

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WifiDirectBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val channelName = "castflow/wifi_direct"
        private const val permissionRequestCode = 4127
    }

    private val methodChannel = MethodChannel(messenger, channelName)
    private val manager = activity.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private val channel = manager?.initialize(activity, activity.mainLooper, null)

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissionAction: (() -> Unit)? = null

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(
                activity.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT),
            )
            "discoverPeers" -> withPermission(result) { discoverPeers(result) }
            "getPeers" -> withPermission(result) { getPeers(result) }
            "connect" -> withPermission(result) {
                val deviceAddress = call.argument<String>("deviceAddress")
                if (deviceAddress.isNullOrBlank()) {
                    result.error("invalid_argument", "deviceAddress is required.", null)
                } else {
                    connect(deviceAddress, result)
                }
            }
            "createGroup" -> withPermission(result) { createGroup(result) }
            "removeGroup" -> withPermission(result) { removeGroup(result) }
            "getConnectionInfo" -> withPermission(result) { getConnectionInfo(result) }
            else -> result.notImplemented()
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != permissionRequestCode) {
            return
        }

        val result = pendingPermissionResult
        val action = pendingPermissionAction
        pendingPermissionResult = null
        pendingPermissionAction = null

        if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            action?.invoke()
        } else {
            result?.error(
                "permission_denied",
                "Nearby Wi-Fi permission is required for Wi-Fi Direct.",
                null,
            )
        }
    }

    private fun withPermission(
        result: MethodChannel.Result,
        action: () -> Unit,
    ) {
        if (manager == null || channel == null) {
            result.error("unsupported", "Wi-Fi Direct is not available on this device.", null)
            return
        }

        val permission = requiredPermission()
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            action()
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "permission_in_progress",
                "Another Wi-Fi Direct permission request is already active.",
                null,
            )
            return
        }

        pendingPermissionResult = result
        pendingPermissionAction = action
        activity.requestPermissions(arrayOf(permission), permissionRequestCode)
    }

    private fun requiredPermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.NEARBY_WIFI_DEVICES
        } else {
            Manifest.permission.ACCESS_FINE_LOCATION
        }
    }

    private fun discoverPeers(result: MethodChannel.Result) {
        manager!!.discoverPeers(channel!!, actionListener(result, "discoverPeers"))
    }

    private fun getPeers(result: MethodChannel.Result) {
        manager!!.requestPeers(channel!!) { peerList ->
            val peers = peerList.deviceList.map(::peerToMap)
            result.success(peers)
        }
    }

    private fun connect(deviceAddress: String, result: MethodChannel.Result) {
        val config = WifiP2pConfig().apply {
            this.deviceAddress = deviceAddress
        }
        manager!!.connect(channel!!, config, actionListener(result, "connect"))
    }

    private fun createGroup(result: MethodChannel.Result) {
        manager!!.createGroup(channel!!, actionListener(result, "createGroup"))
    }

    private fun removeGroup(result: MethodChannel.Result) {
        manager!!.removeGroup(channel!!, actionListener(result, "removeGroup"))
    }

    private fun getConnectionInfo(result: MethodChannel.Result) {
        manager!!.requestConnectionInfo(channel!!) { info ->
            result.success(
                mapOf(
                    "groupFormed" to info.groupFormed,
                    "isGroupOwner" to info.isGroupOwner,
                    "groupOwnerAddress" to info.groupOwnerAddress?.hostAddress,
                ),
            )
        }
    }

    private fun actionListener(
        result: MethodChannel.Result,
        operation: String,
    ): WifiP2pManager.ActionListener {
        return object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                result.success(null)
            }

            override fun onFailure(reason: Int) {
                result.error(
                    "wifi_direct_failure",
                    "${operation} failed: ${failureReason(reason)}",
                    reason,
                )
            }
        }
    }

    private fun failureReason(reason: Int): String {
        return when (reason) {
            WifiP2pManager.P2P_UNSUPPORTED -> "P2P unsupported"
            WifiP2pManager.BUSY -> "framework busy"
            WifiP2pManager.ERROR -> "framework error"
            else -> "unknown reason ${reason}"
        }
    }

    private fun peerToMap(peer: WifiP2pDevice): Map<String, Any?> {
        return mapOf(
            "name" to peer.deviceName,
            "address" to peer.deviceAddress,
            "status" to peer.status,
            "primaryDeviceType" to peer.primaryDeviceType,
            "secondaryDeviceType" to peer.secondaryDeviceType,
        )
    }
}
