import 'package:peer_view_2/features/screen_streaming/models/encoded_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_event.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';

/// Host-side WebSocket server that broadcasts encoded frames to viewers.
abstract interface class WebSocketServerService {
  /// Whether the HTTP/WebSocket server is running.
  bool get isRunning;

  /// Number of currently connected viewer clients.
  int get connectedClientCount;

  /// Lifecycle and broadcast events for the host UI and repository.
  Stream<StreamEvent> get eventStream;

  /// Starts the WebSocket server on [config.port].
  Future<void> start({StreamServerConfig config = const StreamServerConfig()});

  /// Broadcasts an encoded frame to all connected clients.
  Future<void> broadcast(EncodedFrame frame);

  /// Stops the server and disconnects all clients.
  Future<void> stop();
}
