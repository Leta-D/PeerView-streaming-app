import 'dart:typed_data';

import 'package:peer_view_2/features/screen_viewer/models/viewer_connection_event.dart';

/// Connects to a host WebSocket stream and receives encoded frame packets.
///
/// Phase 3+: authentication, quality selection, and remote control messages
/// can be layered on this interface without changing the Cubit.
abstract interface class WebSocketClientService {
  /// Whether a connection to a host is active.
  bool get isConnected;

  /// Current connection lifecycle status.
  ViewerConnectionStatus get connectionStatus;

  /// Encoded wire packets as received from the host (before decoding).
  Stream<Uint8List> get packetStream;

  /// Connection lifecycle events including automatic reconnect attempts.
  Stream<ViewerConnectionEvent> get connectionEvents;

  /// Connects to [url] and begins receiving packets.
  Future<void> connect({required String url});

  /// Enables or disables automatic reconnect after unexpected disconnects.
  void setAutoReconnect({required bool enabled});

  /// Disconnects from the host and cancels pending reconnect attempts.
  Future<void> disconnect();
}
