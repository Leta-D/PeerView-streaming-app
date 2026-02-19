package com.example.peer_view

import android.content.Context
import android.content.Intent
import org.webrtc.*

class WebRTCManager(
    private val context: Context,
    private val mediaProjectionIntent: Intent
) {

    private val eglBase = EglBase.create()
    private val factory: PeerConnectionFactory
    private val videoSource: VideoSource
    private val videoCapturer: VideoCapturer
    private val videoTrack: VideoTrack
    private val peerConnections = mutableMapOf<String, PeerConnection>()

    init {
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .createInitializationOptions()
        )

        factory = PeerConnectionFactory.builder()
            .setVideoEncoderFactory(DefaultVideoEncoderFactory(
                eglBase.eglBaseContext, true, true
            ))
            .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
            .createPeerConnectionFactory()

        videoCapturer = ScreenCapturerAndroid(mediaProjectionIntent, object : MediaProjection.Callback() {})
        videoSource = factory.createVideoSource(false)
        videoCapturer.initialize(
            SurfaceTextureHelper.create("ScreenCaptureThread", eglBase.eglBaseContext),
            context,
            videoSource.capturerObserver
        )
        videoCapturer.startCapture(720, 1280, 30)

        videoTrack = factory.createVideoTrack("SCREEN_TRACK", videoSource)
    }

    fun startHostServer() {
        // Start local WebSocket server on hotspot IP
        // Listen for client SDP offers, ICE candidates
        // When client connects: createPeerConnection(clientId) and send SDP answer
    }

    fun createPeerConnection(clientId: String): PeerConnection? {
        val rtcConfig = PeerConnection.RTCConfiguration(ArrayList())
        return factory.createPeerConnection(rtcConfig, object : PeerConnection.Observer {
            override fun onIceCandidate(candidate: IceCandidate?) {
                // Send candidate to client via WebSocket
            }

            override fun onAddStream(stream: MediaStream?) {}
            override fun onTrack(transceiver: RtpTransceiver?) {}
            override fun onIceConnectionChange(state: PeerConnection.IceConnectionState?) {}
            override fun onSignalingChange(state: PeerConnection.SignalingState?) {}
            override fun onIceConnectionReceivingChange(receiving: Boolean) {}
            override fun onIceGatheringChange(state: PeerConnection.IceGatheringState?) {}
            override fun onRemoveStream(stream: MediaStream?) {}
            override fun onDataChannel(dc: DataChannel?) {}
            override fun onRenegotiationNeeded() {}
        })?.apply {
            addTrack(videoTrack)
            peerConnections[clientId] = this
        }
    }

    fun release() {
        videoCapturer.stopCapture()
        videoSource.dispose()
        peerConnections.values.forEach { it.dispose() }
        factory.dispose()
        eglBase.release()
    }
}
