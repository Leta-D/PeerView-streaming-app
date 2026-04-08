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

  Future<void> stopForegroundService() async {
    try {
      await platform.invokeMethod('stopForegroundService');
    } catch (e) {
      print("Error stoping foreground service: $e");
    }
  }

  Future<MediaStream> captureScreen() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '1280',
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };
    try {
      await startForegroundService();
      print("=========================1==============================");
      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        "video": true,
      });
      print("=========================2==============================");
    } on PlatformException catch (e) {
      print("=========================3==============================");
      print("PlatformException: ${e.message}");
      throw Exception('Error capturing screen: ${e.message}');
    }

    return _screenStream!;
  }

  static Future<RTCVideoRenderer> showScreen(MediaStream screenStream) async {
    RTCVideoRenderer localPreview = RTCVideoRenderer();

    await localPreview.initialize();

    localPreview.srcObject = screenStream;
    return localPreview;
  }

  Future<void> stop() async {
    await stopForegroundService();
    for (var track in _screenStream!.getTracks()) {
      track.stop();
    }
    await _screenStream?.dispose();
  }
}
