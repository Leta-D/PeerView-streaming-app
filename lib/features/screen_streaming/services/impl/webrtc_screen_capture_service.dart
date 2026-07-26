import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peer_view_2/features/screen_streaming/models/captured_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/streaming_exceptions.dart';
import 'package:peer_view_2/features/screen_streaming/services/screen_capture_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// WebRTC-backed screen capture that keeps all frames in memory.
class WebRtcScreenCaptureService implements ScreenCaptureService {
  WebRtcScreenCaptureService({
    MethodChannel? platformChannel,
    Duration frameCaptureInterval = const Duration(milliseconds: 100),
  })  : _platformChannel = platformChannel ?? const MethodChannel('screen_capture'),
        _frameCaptureInterval = frameCaptureInterval;

  final MethodChannel _platformChannel;
  final Duration _frameCaptureInterval;

  final StreamController<CapturedFrame> _frameController =
      StreamController<CapturedFrame>.broadcast();

  MediaStream? _screenStream;
  MediaStreamTrack? _videoTrack;
  Timer? _frameCaptureTimer;
  int _sequenceNumber = 0;
  bool _isCapturing = false;

  @override
  Stream<CapturedFrame> get frameStream => _frameController.stream;

  @override
  bool get isCapturing => _isCapturing;

  @override
  Object? get previewStream => _isCapturing ? _screenStream : null;

  @override
  Future<void> startCapture() async {
    if (_isCapturing) {
      return;
    }

    await _ensurePermissions();

    try {
      if (WebRTC.platformIsAndroid) {
        final granted = await Helper.requestCapturePermission();
        if (!granted) {
          throw const ScreenCaptureException('Screen capture permission denied.');
        }

        await _startForegroundService();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });

      final videoTracks = _screenStream!.getVideoTracks();
      if (videoTracks.isEmpty) {
        throw const ScreenCaptureException('No video track available from screen capture.');
      }

      _videoTrack = videoTracks.first;
      _videoTrack!.onEnded = () {
        if (_isCapturing) {
          unawaited(stopCapture());
        }
      };

      _isCapturing = true;
      _startFrameCaptureLoop();
    } on PlatformException catch (error) {
      await _stopForegroundService();
      throw ScreenCaptureException('Failed to start screen capture.', cause: error);
    } catch (error) {
      await _stopForegroundService();
      if (error is ScreenCaptureException) {
        rethrow;
      }
      throw ScreenCaptureException(
        'Unexpected error while starting screen capture.',
        cause: error,
      );
    }
  }

  @override
  Future<void> stopCapture() async {
    if (!_isCapturing) {
      return;
    }

    _isCapturing = false;
    _frameCaptureTimer?.cancel();
    _frameCaptureTimer = null;

    final track = _videoTrack;
    _videoTrack = null;
    if (track != null) {
      track.onEnded = null;
      await track.stop();
    }

    final stream = _screenStream;
    _screenStream = null;
    if (stream != null) {
      for (final activeTrack in stream.getTracks()) {
        await activeTrack.stop();
      }
      await stream.dispose();
    }

    await _stopForegroundService();
  }

  Future<void> _ensurePermissions() async {
    if (!WebRTC.platformIsAndroid) {
      return;
    }

    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      final result = await Permission.notification.request();
      if (result.isPermanentlyDenied) {
        throw const ScreenCaptureException(
          'Notification permission is required for screen capture on Android.',
        );
      }
      if (!result.isGranted && !result.isLimited) {
        throw const ScreenCaptureException('Notification permission was denied.');
      }
    } else if (notificationStatus.isPermanentlyDenied) {
      throw const ScreenCaptureException(
        'Notification permission is permanently denied. Enable it in settings.',
      );
    }
  }

  void _startFrameCaptureLoop() {
    _frameCaptureTimer?.cancel();
    _frameCaptureTimer = Timer.periodic(_frameCaptureInterval, (_) {
      unawaited(_captureAndEmitFrame());
    });
  }

  Future<void> _captureAndEmitFrame() async {
    final track = _videoTrack;
    if (!_isCapturing || track == null || _frameController.isClosed) {
      return;
    }

    try {
      final buffer = await track.captureFrame();
      final data = buffer.asUint8List();
      if (data.isEmpty) {
        return;
      }

      final settings = track.getSettings();
      _frameController.add(
        CapturedFrame(
          data: data,
          sequenceNumber: _sequenceNumber++,
          timestamp: DateTime.now(),
          width: _readIntSetting(settings, 'width'),
          height: _readIntSetting(settings, 'height'),
        ),
      );
    } catch (_) {
      // Skip transient capture failures.
    }
  }

  int? _readIntSetting(Map<String, dynamic> settings, String key) {
    final value = settings[key];
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return null;
  }

  Future<void> _startForegroundService() async {
    if (!WebRTC.platformIsAndroid) {
      return;
    }

    try {
      await _platformChannel.invokeMethod<void>('startForegroundService');
    } on PlatformException catch (error) {
      throw ScreenCaptureException(
        'Failed to start Android foreground service.',
        cause: error,
      );
    }
  }

  Future<void> _stopForegroundService() async {
    if (!WebRTC.platformIsAndroid) {
      return;
    }

    try {
      await _platformChannel.invokeMethod<void>('stopForegroundService');
    } on PlatformException catch (error) {
      throw ScreenCaptureException(
        'Failed to stop Android foreground service.',
        cause: error,
      );
    }
  }

  void dispose() {
    unawaited(stopCapture());
    if (!_frameController.isClosed) {
      _frameController.close();
    }
  }
}
