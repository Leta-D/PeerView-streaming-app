import 'package:peer_view_2/features/screen_streaming/models/captured_frame.dart';

/// Captures the host screen and exposes in-memory frames.
///
/// Implementations must never persist recordings to local storage.
abstract interface class ScreenCaptureService {
  /// Whether screen capture is currently active.
  bool get isCapturing;

  /// Live capture source for in-app preview while streaming.
  ///
  /// Typed as [Object] so presentation code can cast to the platform media type.
  Object? get previewStream;

  /// Broadcast stream of raw captured frames held in memory.
  Stream<CapturedFrame> get frameStream;

  /// Requests permissions and starts continuous screen capture.
  Future<void> startCapture();

  /// Stops capture and releases in-memory resources.
  Future<void> stopCapture();
}
