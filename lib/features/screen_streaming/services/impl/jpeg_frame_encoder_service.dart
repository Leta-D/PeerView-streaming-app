import 'package:peer_view_2/features/screen_streaming/models/captured_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/encoded_frame.dart';
import 'package:peer_view_2/features/screen_streaming/services/frame_encoder_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/frame_packet_codec.dart';

/// JPEG frame encoder using the [FramePacketCodec] wire format.
///
/// Swap this class to plug in H.264, VP8, or adaptive quality later.
class JpegFrameEncoderService implements FrameEncoderService {
  @override
  EncodedFrame encode(CapturedFrame frame) {
    return FramePacketCodec.encodeFrame(frame);
  }
}
