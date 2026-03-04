package com.example.peer_view

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder

class ScreenRecordService : Service() {

    companion object {
        var mediaProjection: MediaProjection? = null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundNotification()

        val resultCode = intent?.getIntExtra("resultCode", -1) ?: return START_NOT_STICKY
        val data = intent.getParcelableExtra<Intent>("data") ?: return START_NOT_STICKY


        val projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        mediaProjection = projectionManager.getMediaProjection(resultCode, data)

        if (mediaProjection == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        return START_STICKY
    }

    private fun startForegroundNotification() {
        val channelId = "screen_record_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Screen Sharing",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        val notification = Notification.Builder(this, channelId)
            .setContentTitle("Screen sharing active")
            .setSmallIcon(android.R.drawable.presence_video_online)
            .build()

        startForeground(1, notification)
    }

    override fun onDestroy() {
        mediaProjection?.stop()
        mediaProjection = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}