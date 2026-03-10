import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenShareService {
  RTCPeerConnection? _pc;

  Future<RTCPeerConnection> startStream(MediaStream capturedScreen) async {
    _pc = await createPeerConnection({});

    MediaStream screenStream = capturedScreen;
    screenStream.getTracks().forEach((track) {
      _pc!.addTrack(track, screenStream);
    });

    return _pc!;
  }

  Future<void> stopStream() async {
    await _pc!.close();
  }
}
