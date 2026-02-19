package com.example.peer_view

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import org.webrtc.*

class ScreenRecordService : Service() {

    var mediaProjection: MediaProjection? = null
    var mediaProjectionIntent: Intent? = null

    private lateinit var webRTCManager: WebRTCManager

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val resultCode = intent?.getIntExtra("resultCode", -1) ?: return START_NOT_STICKY
        val data = intent.getParcelableExtra<Intent>("data") ?: return START_NOT_STICKY

        startForegroundNotification()

        val projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data)
        mediaProjectionIntent = data

        if (mediaProjection == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        // Initialize WebRTC Manager
        webRTCManager = WebRTCManager(this, mediaProjectionIntent!!)

        // TODO: Start local WebSocket server to accept clients over hotspot
        webRTCManager.startHostServer()

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
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = Notification.Builder(this, channelId)
            .setContentTitle("Screen sharing active")
            .setContentText("Your screen is being streamed")
            .setSmallIcon(android.R.drawable.presence_video_online)
            .build()

        startForeground(1, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        webRTCManager.release()
        mediaProjection?.stop()
        mediaProjection = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
