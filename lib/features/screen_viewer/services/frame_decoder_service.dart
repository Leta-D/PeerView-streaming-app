import 'dart:typed_data';

import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';

/// Decodes encoded wire packets into displayable frames.
///
/// Swap implementations to support H.264, VP8, or adaptive quality later.
abstract interface class FrameDecoderService {
  /// Decodes a wire packet into a [DecodedFrame], or null if invalid.
  DecodedFrame? decode(Uint8List packet);
}
