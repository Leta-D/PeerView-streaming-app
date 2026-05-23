import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_connection_event.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_exceptions.dart';
import 'package:peer_view_2/features/screen_viewer/repositories/viewer_repository.dart';
import 'package:peer_view_2/features/screen_viewer/services/frame_decoder_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/host_discovery_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/websocket_client_service.dart';

/// Wires discovery → WebSocket client → frame decoder for the viewer feature.
class ViewerRepositoryImpl implements ViewerRepository {
  ViewerRepositoryImpl({
    required HostDiscoveryService hostDiscoveryService,
    required WebSocketClientService webSocketClientService,
    required FrameDecoderService frameDecoderService,
    Connectivity? connectivity,
  })  : _hostDiscoveryService = hostDiscoveryService,
        _webSocketClientService = webSocketClientService,
        _frameDecoderService = frameDecoderService,
        _connectivity = connectivity ?? Connectivity() {
    _packetSubscription = _webSocketClientService.packetStream.listen(_handlePacket);
    _connectionSubscription =
        _webSocketClientService.connectionEvents.listen(_forwardConnectionEvent);
  }

  final HostDiscoveryService _hostDiscoveryService;
  final WebSocketClientService _webSocketClientService;
  final FrameDecoderService _frameDecoderService;
  final Connectivity _connectivity;

  final StreamController<ViewerConnectionEvent> _connectionController =
      StreamController<ViewerConnectionEvent>.broadcast();
  final StreamController<DecodedFrame> _frameController =
      StreamController<DecodedFrame>.broadcast();

  StreamSubscription<Uint8List>? _packetSubscription;
  StreamSubscription<ViewerConnectionEvent>? _connectionSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  DiscoveredHost? _connectedHost;
  bool _shouldResumeDiscoveryAfterDisconnect = false;
  StreamServerConfig _discoveryConfig = const StreamServerConfig();

  @override
  Stream<List<DiscoveredHost>> get discoveredHostsStream =>
      _hostDiscoveryService.discoveredHostsStream;

  @override
  Stream<ViewerConnectionEvent> get connectionEvents => _connectionController.stream;

  @override
  Stream<DecodedFrame> get frameStream => _frameController.stream;

  @override
  bool get isScanning => _hostDiscoveryService.isScanning;

  @override
  bool get isConnected => _webSocketClientService.isConnected;

  @override
  Future<void> startDiscovery({
    StreamServerConfig config = const StreamServerConfig(),
  }) {
    _discoveryConfig = config;
    _listenToConnectivityChanges();
    return _hostDiscoveryService.startDiscovery(
      port: config.port,
      webSocketPath: config.webSocketPath,
    );
  }

  @override
  Future<void> refreshDiscovery({
    StreamServerConfig config = const StreamServerConfig(),
  }) {
    _discoveryConfig = config;
    return _hostDiscoveryService.refresh(
      port: config.port,
      webSocketPath: config.webSocketPath,
    );
  }

  @override
  Future<void> stopDiscovery() {
    return _hostDiscoveryService.stopDiscovery();
  }

  Future<void> _resumeDiscovery() {
    return _hostDiscoveryService.startDiscovery(
      port: _discoveryConfig.port,
      webSocketPath: _discoveryConfig.webSocketPath,
    );
  }

  @override
  Future<void> connect(DiscoveredHost host) async {
    _connectedHost = host;
    _shouldResumeDiscoveryAfterDisconnect = _hostDiscoveryService.isScanning;

    if (_hostDiscoveryService.isScanning) {
      await _hostDiscoveryService.stopDiscovery();
    }

    _webSocketClientService.setAutoReconnect(enabled: true);

    try {
      await _webSocketClientService.connect(url: host.websocketUrl);
    } catch (error) {
      _connectedHost = null;
      if (_shouldResumeDiscoveryAfterDisconnect) {
        await _resumeDiscovery();
      }
      if (error is ViewerConnectionException) {
        rethrow;
      }
      throw ViewerConnectionException(
        'Failed to connect to ${host.websocketUrl}',
        cause: error,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _webSocketClientService.setAutoReconnect(enabled: false);
    await _webSocketClientService.disconnect();
    _connectedHost = null;

    if (_shouldResumeDiscoveryAfterDisconnect) {
      _shouldResumeDiscoveryAfterDisconnect = false;
      await _resumeDiscovery();
    }
  }

  void _handlePacket(Uint8List packet) {
    try {
      final decoded = _frameDecoderService.decode(packet);
      if (decoded == null) {
        // Skip non-frame / corrupt packets without tearing down the session.
        return;
      }

      if (!_frameController.isClosed) {
        _frameController.add(decoded);
      }
    } catch (_) {
      // Keep the WebSocket open; one bad packet should not kill playback.
    }
  }

  void _forwardConnectionEvent(ViewerConnectionEvent event) {
    if (_connectionController.isClosed) {
      return;
    }
    _connectionController.add(event);

    if (event is ViewerConnectionFailedEvent ||
        (event is ViewerDisconnectedEvent &&
            event.reason != 'Disconnected by user')) {
      _connectedHost = null;
      if (_shouldResumeDiscoveryAfterDisconnect) {
        unawaited(_resumeDiscovery());
      }
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription ??=
        _connectivity.onConnectivityChanged.listen((_) async {
      if (!_webSocketClientService.isConnected &&
          _hostDiscoveryService.isScanning) {
        await _hostDiscoveryService.refresh(
          port: _discoveryConfig.port,
          webSocketPath: _discoveryConfig.webSocketPath,
        );
      }
    });
  }

  Future<void> dispose() async {
    await _packetSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await disconnect();
    await _hostDiscoveryService.stopDiscovery();
    await _connectionController.close();
    await _frameController.close();
  }
}
