import 'dart:typed_data';

import 'package:peer_view_2/features/screen_streaming/services/frame_packet_codec.dart';
import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';
import 'package:peer_view_2/features/screen_viewer/services/frame_decoder_service.dart';

/// Decodes PV2 JPEG wire packets from the host into [DecodedFrame] objects.
class JpegFrameDecoderService implements FrameDecoderService {
  @override
  DecodedFrame? decode(Uint8List packet) {
    final header = FramePacketCodec.decodeHeader(packet);
    final jpeg = FramePacketCodec.decodeJpegPayload(packet);

    if (header == null || jpeg == null || jpeg.isEmpty) {
      return null;
    }

    return DecodedFrame(
      imageBytes: jpeg,
      sequenceNumber: header.sequenceNumber,
      timestamp: header.timestamp,
      width: header.width,
      height: header.height,
    );
  }
}
