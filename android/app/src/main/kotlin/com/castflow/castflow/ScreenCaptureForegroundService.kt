package com.castflow.castflow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.ResultReceiver

class ScreenCaptureForegroundService : Service() {
    companion object {
        const val notificationChannelId = "castflow_screen_capture"
        const val notificationId = 2401
        const val extraReadyReceiver = "castflow.extra.SCREEN_CAPTURE_READY_RECEIVER"
        const val readyResultCode = 1
    }

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(notificationId, buildNotification())

        val receiver = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent?.getParcelableExtra(extraReadyReceiver, ResultReceiver::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra(extraReadyReceiver)
        }
        receiver?.send(readyResultCode, null)

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            notificationChannelId,
            "CastFlow screen capture",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = "Keeps CastFlow screen sharing active while you are casting."
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, notificationChannelId)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("CastFlow is sharing your screen")
            .setContentText("Screen mirroring is active")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .build()
    }
}
