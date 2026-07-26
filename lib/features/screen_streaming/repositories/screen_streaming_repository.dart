import 'package:peer_view_2/features/screen_streaming/models/host_network_info.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_event.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';

/// Coordinates capture, encoding, and WebSocket broadcasting for the host.
abstract interface class ScreenStreamingRepository {
  bool get isServerRunning;
  bool get isStreaming;
  int get connectedClientCount;
  HostNetworkInfo? get networkInfo;
  Object? get previewStream;

  Stream<StreamEvent> get eventStream;

  /// Loads current network information for display before streaming starts.
  Future<HostNetworkInfo> loadNetworkInfo({StreamServerConfig config});

  /// Starts the full host pipeline:
  /// network resolution → WebSocket server → capture → encode → broadcast.
  Future<void> startStreaming({StreamServerConfig config});

  /// Stops capture and the WebSocket server.
  Future<void> stopStreaming();
}
