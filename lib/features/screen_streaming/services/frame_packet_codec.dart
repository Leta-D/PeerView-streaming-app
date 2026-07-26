import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:peer_view_2/features/screen_streaming/models/captured_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/encoded_frame.dart';

/// Binary wire format for encoded JPEG frames sent to viewer clients.
///
/// Layout (big-endian):
/// - 4 bytes magic `PV2\0`
/// - 4 bytes sequence number
/// - 4 bytes width (0 if unknown)
/// - 4 bytes height (0 if unknown)
/// - 8 bytes timestamp (Unix ms)
/// - remaining bytes: JPEG payload
class FramePacketCodec {
  static const magic = [0x50, 0x56, 0x32, 0x00]; // PV2\0
  static const headerLength = 24;

  static Uint8List encode(CapturedFrame frame) {
    final packet = Uint8List(headerLength + frame.data.length);
    final view = ByteData.view(packet.buffer);

    for (var i = 0; i < magic.length; i++) {
      packet[i] = magic[i];
    }

    view.setUint32(4, frame.sequenceNumber);
    view.setUint32(8, frame.width ?? 0);
    view.setUint32(12, frame.height ?? 0);
    view.setUint64(16, frame.timestamp.millisecondsSinceEpoch);
    packet.setRange(headerLength, packet.length, frame.data);

    return packet;
  }

  static EncodedFrame encodeFrame(CapturedFrame frame) {
    return EncodedFrame(
      data: encode(frame),
      sequenceNumber: frame.sequenceNumber,
      timestamp: frame.timestamp,
      width: frame.width,
      height: frame.height,
      mimeType: frame.mimeType,
    );
  }

  static String streamStartMessage({required String host, required int port}) {
    return jsonEncode({
      'type': 'stream_start',
      'mimeType': 'image/jpeg',
      'host': host,
      'port': port,
      'client': 'peer_view_2_host',
    });
  }

  static String streamEndMessage() {
    return jsonEncode({'type': 'stream_end'});
  }

  /// Extracts the JPEG payload from a wire packet, or null if invalid.
  static Uint8List? decodeJpegPayload(Uint8List packet) {
    if (packet.length <= headerLength) {
      return null;
    }

    for (var i = 0; i < magic.length; i++) {
      if (packet[i] != magic[i]) {
        return null;
      }
    }

    return Uint8List.fromList(packet.sublist(headerLength));
  }

  /// Parses header metadata from a wire packet without copying the payload.
  static ({int sequenceNumber, int? width, int? height, DateTime timestamp})?
      decodeHeader(Uint8List packet) {
    if (packet.length <= headerLength) {
      return null;
    }

    for (var i = 0; i < magic.length; i++) {
      if (packet[i] != magic[i]) {
        return null;
      }
    }

    final view = ByteData.view(packet.buffer, packet.offsetInBytes, packet.length);
    final width = view.getUint32(8);
    final height = view.getUint32(12);

    return (
      sequenceNumber: view.getUint32(4),
      width: width == 0 ? null : width,
      height: height == 0 ? null : height,
      timestamp: DateTime.fromMillisecondsSinceEpoch(view.getUint64(16)),
    );
  }
}
