import 'dart:async';
import 'dart:io';
import 'package:peer_view_2/features/screen_streaming/models/encoded_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_event.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:peer_view_2/features/screen_streaming/models/streaming_exceptions.dart';
import 'package:peer_view_2/features/screen_streaming/services/frame_packet_codec.dart';
import 'package:peer_view_2/features/screen_streaming/services/websocket_server_service.dart';

/// Host-side WebSocket server that accepts multiple viewer clients.
class DartWebSocketServerService implements WebSocketServerService {
  DartWebSocketServerService();

  HttpServer? _server;
  StreamServerConfig _config = const StreamServerConfig();
  final Map<String, WebSocket> _clients = {};
  final StreamController<StreamEvent> _eventController =
      StreamController<StreamEvent>.broadcast();

  int _clientCounter = 0;
  String? _hostIpForHandshake;

  @override
  bool get isRunning => _server != null;

  @override
  int get connectedClientCount => _clients.length;

  @override
  Stream<StreamEvent> get eventStream => _eventController.stream;

  /// Sets host metadata included in the stream-start handshake message.
  void updateHostMetadata({required String hostIpAddress}) {
    _hostIpForHandshake = hostIpAddress;
  }

  @override
  Future<void> start({StreamServerConfig config = const StreamServerConfig()}) async {
    if (isRunning) {
      return;
    }

    _config = config;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, config.port);

      _server!.listen(
        _handleRequest,
        onError: (Object error) {
          _emit(
            StreamErrorEvent(
              timestamp: DateTime.now(),
              message: 'WebSocket server error',
              cause: error,
            ),
          );
        },
      );

      final host = _hostIpForHandshake ?? '0.0.0.0';
      _emit(
        StreamServerStartedEvent(
          timestamp: DateTime.now(),
          port: config.port,
          websocketUrl: 'ws://$host:${config.port}${config.webSocketPath}',
        ),
      );
    } catch (error) {
      throw WebSocketServerException(
        'Failed to start WebSocket server on port ${config.port}',
        cause: error,
      );
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    if (request.uri.path != _config.webSocketPath &&
        request.uri.path != _config.webSocketPath.replaceFirst('/', '')) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      final clientId = 'client-${++_clientCounter}';
      _clients[clientId] = socket;

      socket.add(
        FramePacketCodec.streamStartMessage(
          host: _hostIpForHandshake ?? '0.0.0.0',
          port: _config.port,
        ),
      );

      _emit(
        StreamClientConnectedEvent(
          timestamp: DateTime.now(),
          clientId: clientId,
          connectedClientCount: _clients.length,
        ),
      );

      socket.listen(
        _handleClientMessage,
        onDone: () => _removeClient(clientId),
        onError: (_) => _removeClient(clientId),
        cancelOnError: true,
      );
    } catch (error) {
      _emit(
        StreamErrorEvent(
          timestamp: DateTime.now(),
          message: 'Failed to accept WebSocket client',
          cause: error,
        ),
      );
    }
  }

  void _handleClientMessage(dynamic message) {
    // Phase 2+: authentication, remote control, pause/resume commands.
  }

  void _removeClient(String clientId) {
    final removed = _clients.remove(clientId);
    if (removed == null) {
      return;
    }

    _emit(
      StreamClientDisconnectedEvent(
        timestamp: DateTime.now(),
        clientId: clientId,
        connectedClientCount: _clients.length,
      ),
    );
  }

  @override
  Future<void> broadcast(EncodedFrame frame) async {
    if (_clients.isEmpty) {
      return;
    }

    final payload = frame.data;
    final disconnectedClients = <String>[];

    for (final entry in _clients.entries) {
      try {
        entry.value.add(payload);
      } catch (error) {
        disconnectedClients.add(entry.key);
        _emit(
          StreamErrorEvent(
            timestamp: DateTime.now(),
            message: 'Failed to broadcast to ${entry.key}',
            cause: error,
          ),
        );
      }
    }

    for (final clientId in disconnectedClients) {
      _removeClient(clientId);
    }

    _emit(
      StreamFrameBroadcastEvent(
        timestamp: DateTime.now(),
        sequenceNumber: frame.sequenceNumber,
        recipientCount: _clients.length,
      ),
    );
  }

  @override
  Future<void> stop() async {
    for (final socket in _clients.values) {
      try {
        socket.add(FramePacketCodec.streamEndMessage());
      } catch (_) {
        // Client may already be gone.
      }
      await socket.close();
    }
    _clients.clear();

    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
      _emit(StreamServerStoppedEvent(timestamp: DateTime.now()));
    }
  }

  void _emit(StreamEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}
