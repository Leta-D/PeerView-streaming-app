package com.example.peer_view

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "screen_record"
    private val SCREEN_CAPTURE_REQUEST_CODE = 101
    private lateinit var projectionManager: MediaProjectionManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        projectionManager =
            getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "startScreenRecord" -> {
                    val intent = projectionManager.createScreenCaptureIntent()
                    startActivityForResult(intent, SCREEN_CAPTURE_REQUEST_CODE)
                    result.success(null)
                }

                "stopScreenRecord" -> {
                    stopService(Intent(this, ScreenRecordService::class.java))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SCREEN_CAPTURE_REQUEST_CODE &&
            resultCode == Activity.RESULT_OK &&
            data != null
        ) {
            val serviceIntent = Intent(this, ScreenRecordService::class.java)
            serviceIntent.putExtra("resultCode", resultCode)
            serviceIntent.putExtra("data", data)
            startForegroundService(serviceIntent)
        }
    }
}
