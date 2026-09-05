package com.castflow.castflow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder

class ScreenCaptureForegroundService : Service() {
    companion object {
        const val notificationChannelId = "castflow_screen_capture"
        const val notificationId = 2401
    }

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(notificationId, buildNotification())
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
