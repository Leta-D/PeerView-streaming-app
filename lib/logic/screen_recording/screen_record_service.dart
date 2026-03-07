import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenRecordService {
  MediaStream? _screenStream;

  final platform = MethodChannel('screen_capture');

  Future<void> startForegroundService() async {
    try {
      await platform.invokeMethod('startForegroundService');
    } catch (e) {
      print("Error starting foreground service: $e");
    }
  }

  Future<MediaStream> captureScreen() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': true,
      // 'video': {
      //   'mandatory': {
      //     'minWidth': '1280',
      //     'minHeight': '720',
      //     'minFrameRate': '30',
      //   },
      //   'facingMode': 'user',
      //   'optional': [],
      // },
    };
    try {
      await startForegroundService();
      _screenStream = await navigator.mediaDevices.getDisplayMedia(
        mediaConstraints,
      );
    } on PlatformException catch (e) {
      throw Exception('Error capturing screen: ${e.message}');
    }

    return _screenStream!;
  }

  Future<RTCVideoRenderer> showScreen() async {
    RTCVideoRenderer localPreview = RTCVideoRenderer();

    await localPreview.initialize();

    localPreview.srcObject = await captureScreen();
    return localPreview;
  }

  Future<void> stop() async {
    await _screenStream?.dispose();
  }
}
