import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:peer_view_2/features/screen_viewer/models/viewer_connection_event.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_exceptions.dart';
import 'package:peer_view_2/features/screen_viewer/services/websocket_client_service.dart';

/// WebSocket viewer client with automatic reconnect support.
class ReconnectingWebSocketClientService implements WebSocketClientService {
  ReconnectingWebSocketClientService({
    this.connectTimeout = const Duration(seconds: 10),
    this.maxReconnectAttempts = 5,
  });

  final Duration connectTimeout;
  final int maxReconnectAttempts;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  String? _activeUrl;
  bool _autoReconnect = true;
  bool _manualDisconnect = false;
  int _reconnectAttempt = 0;

  final StreamController<Uint8List> _packetController =
      StreamController<Uint8List>.broadcast();
  final StreamController<ViewerConnectionEvent> _connectionController =
      StreamController<ViewerConnectionEvent>.broadcast();

  ViewerConnectionStatus _status = ViewerConnectionStatus.disconnected;

  @override
  bool get isConnected => _socket != null;

  @override
  ViewerConnectionStatus get connectionStatus => _status;

  @override
  Stream<Uint8List> get packetStream => _packetController.stream;

  @override
  Stream<ViewerConnectionEvent> get connectionEvents => _connectionController.stream;

  @override
  void setAutoReconnect({required bool enabled}) {
    _autoReconnect = enabled;
  }

  @override
  Future<void> connect({required String url}) async {
    _manualDisconnect = false;
    _activeUrl = _normalizeUrl(url);

    if (_activeUrl!.isEmpty) {
      throw const ViewerConnectionException('WebSocket URL cannot be empty.');
    }

    await _openConnection(isReconnect: false);
  }

  Future<void> _openConnection({required bool isReconnect}) async {
    _reconnectTimer?.cancel();
    _status = isReconnect
        ? ViewerConnectionStatus.reconnecting
        : ViewerConnectionStatus.connecting;

    _emit(
      isReconnect
          ? ViewerReconnectingEvent(
              timestamp: DateTime.now(),
              attempt: _reconnectAttempt,
              maxAttempts: maxReconnectAttempts,
            )
          : ViewerConnectingEvent(
              timestamp: DateTime.now(),
              url: _activeUrl!,
            ),
    );

    await _subscription?.cancel();
    _subscription = null;

    final previousSocket = _socket;
    _socket = null;
    if (previousSocket != null) {
      await previousSocket.close();
    }

    try {
      _socket = await WebSocket.connect(_activeUrl!).timeout(connectTimeout);
      _reconnectAttempt = 0;
      _status = ViewerConnectionStatus.connected;

      _emit(
        ViewerConnectedEvent(
          timestamp: DateTime.now(),
          url: _activeUrl!,
        ),
      );

      _subscription = _socket!.listen(
        _handleMessage,
        onDone: _handleSocketClosed,
        onError: (_) => _handleSocketClosed(),
        cancelOnError: true,
      );
    } on TimeoutException {
      await _handleConnectionFailure(
        'Connection timed out while connecting to $_activeUrl',
      );
    } catch (error) {
      await _handleConnectionFailure(
        'Failed to connect to $_activeUrl',
        cause: error,
      );
    }
  }

  void _handleMessage(dynamic message) {
    if (message is! List<int>) {
      return;
    }

    if (_packetController.isClosed) {
      return;
    }

    _packetController.add(Uint8List.fromList(message));
  }

  Future<void> _handleSocketClosed() async {
    if (_manualDisconnect) {
      return;
    }

    _status = ViewerConnectionStatus.disconnected;
    _emit(
      ViewerDisconnectedEvent(
        timestamp: DateTime.now(),
        reason: 'Host connection closed',
      ),
    );

    if (_autoReconnect && _activeUrl != null) {
      await _scheduleReconnect();
    }
  }

  Future<void> _handleConnectionFailure(String message, {Object? cause}) async {
    if (_manualDisconnect) {
      return;
    }

    if (_autoReconnect && _activeUrl != null && _reconnectAttempt < maxReconnectAttempts) {
      await _scheduleReconnect();
      return;
    }

    _status = ViewerConnectionStatus.failed;
    _emit(
      ViewerConnectionFailedEvent(
        timestamp: DateTime.now(),
        message: message,
        cause: cause,
      ),
    );
  }

  Future<void> _scheduleReconnect() async {
    _reconnectAttempt++;
    if (_reconnectAttempt > maxReconnectAttempts) {
      _status = ViewerConnectionStatus.failed;
      _emit(
        ViewerConnectionFailedEvent(
          timestamp: DateTime.now(),
          message: 'Unable to reconnect after $maxReconnectAttempts attempts',
        ),
      );
      return;
    }

    _status = ViewerConnectionStatus.reconnecting;
    _emit(
      ViewerReconnectingEvent(
        timestamp: DateTime.now(),
        attempt: _reconnectAttempt,
        maxAttempts: maxReconnectAttempts,
      ),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectAttempt * 2), () {
      unawaited(_openConnection(isReconnect: true));
    });
  }

  @override
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _activeUrl = null;

    await _subscription?.cancel();
    _subscription = null;

    final socket = _socket;
    _socket = null;

    if (socket != null) {
      await socket.close();
    }

    _status = ViewerConnectionStatus.disconnected;
    _emit(
      ViewerDisconnectedEvent(
        timestamp: DateTime.now(),
        reason: 'Disconnected by user',
      ),
    );
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('ws://') || trimmed.startsWith('wss://')) {
      return trimmed;
    }
    return 'ws://$trimmed';
  }

  void _emit(ViewerConnectionEvent event) {
    if (!_connectionController.isClosed) {
      _connectionController.add(event);
    }
  }

  void dispose() {
    disconnect();
    _packetController.close();
    _connectionController.close();
  }
}
