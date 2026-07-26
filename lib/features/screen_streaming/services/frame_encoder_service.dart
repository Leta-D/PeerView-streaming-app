import 'package:peer_view_2/features/screen_streaming/models/captured_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/encoded_frame.dart';

/// Encodes captured frames before network transmission.
///
/// Replace this implementation to swap compression codecs or transports later.
abstract interface class FrameEncoderService {
  /// Encodes a single captured frame for broadcast.
  EncodedFrame encode(CapturedFrame frame);
}
