import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Display-ready frame produced by [FrameDecoderService].
class DecodedFrame extends Equatable {
  const DecodedFrame({
    required this.imageBytes,
    required this.sequenceNumber,
    required this.timestamp,
    this.width,
    this.height,
    this.mimeType = 'image/jpeg',
  });

  final Uint8List imageBytes;
  final int sequenceNumber;
  final DateTime timestamp;
  final int? width;
  final int? height;
  final String mimeType;

  @override
  List<Object?> get props => [
        sequenceNumber,
        timestamp,
        width,
        height,
        mimeType,
        imageBytes.length,
      ];
}
