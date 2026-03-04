// screen_share_service.dart
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenShareService {
  static const _channel = MethodChannel('screen_record');

  RTCPeerConnection? _pc;
  MediaStream? _stream;

  Future<RTCPeerConnection> start() async {
    final projection = Map<String, dynamic>.from(
      await _channel.invokeMethod('startScreenRecord'),
    );

    _stream = await navigator.mediaDevices.getDisplayMedia({
      'video': {
        'mandatory': {
          'android.mediaProjection': {
            'resultCode': projection['resultCode'],
            'data': projection['data'],
          },
        },
      },
      'audio': false,
    });

    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    for (final track in _stream!.getVideoTracks()) {
      _pc!.addTrack(track, _stream!);
    }

    return _pc!;
  }

  Future<void> stop() async {
    // await _channel.invokeMethod('stopScreenRecord');
    await _stream?.dispose();
    await _pc?.close();
  }
}
