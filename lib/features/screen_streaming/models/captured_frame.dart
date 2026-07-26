import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Raw frame captured from the device screen and held in memory.
class CapturedFrame extends Equatable {
  const CapturedFrame({
    required this.data,
    required this.sequenceNumber,
    required this.timestamp,
    this.width,
    this.height,
    this.mimeType = 'image/jpeg',
  });

  final Uint8List data;
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
        data.length,
      ];
}
