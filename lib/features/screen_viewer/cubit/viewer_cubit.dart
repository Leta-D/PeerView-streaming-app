import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/core/settings/stream_settings_store.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_state.dart';
import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_connection_event.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_exceptions.dart';
import 'package:peer_view_2/features/screen_viewer/repositories/viewer_repository.dart';

/// Coordinates host discovery, connection, and playback for the viewer feature.
class ViewerCubit extends Cubit<ViewerState> {
  ViewerCubit({
    required ViewerRepository repository,
    required StreamSettingsStore settingsStore,
  })  : _repository = repository,
        _settingsStore = settingsStore,
        super(const ViewerState()) {
    _hostsSubscription = _repository.discoveredHostsStream.listen(_handleHostsUpdated);
    _connectionSubscription = _repository.connectionEvents.listen(_handleConnectionEvent);
    _frameSubscription = _repository.frameStream.listen(_handleFrameReceived);
  }

  final ViewerRepository _repository;
  final StreamSettingsStore _settingsStore;

  StreamServerConfig get _discoveryConfig => _settingsStore.config;

  int get discoveryPort => _discoveryConfig.port;

  String get discoveryPath => _discoveryConfig.webSocketPath;

  StreamSubscription<List<DiscoveredHost>>? _hostsSubscription;
  StreamSubscription<ViewerConnectionEvent>? _connectionSubscription;
  StreamSubscription<DecodedFrame>? _frameSubscription;

  Future<void> initialize() async {
    await scanForHosts();
  }

  Future<void> scanForHosts() async {
    if (!state.canScan && state.phase != ViewerPhase.scanning) {
      return;
    }

    emit(
      state.copyWith(
        phase: ViewerPhase.scanning,
        streamStatus: 'Scanning LAN...',
        connectionStatusLabel: 'Scanning',
        clearError: true,
      ),
    );

    try {
      final config = _discoveryConfig;
      if (_repository.isScanning) {
        await _repository.refreshDiscovery(config: config);
      } else {
        await _repository.startDiscovery(config: config);
      }
    } on HostDiscoveryException catch (error) {
      emit(
        state.copyWith(
          phase: ViewerPhase.error,
          lastError: error.message,
          streamStatus: 'Scan failed',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: ViewerPhase.error,
          lastError: error.toString(),
          streamStatus: 'Scan failed',
        ),
      );
    }
  }

  Future<void> connectToHost(DiscoveredHost host) async {
    emit(
      state.copyWith(
        phase: ViewerPhase.connecting,
        selectedHost: host,
        streamStatus: 'Connecting...',
        connectionStatus: ViewerConnectionStatus.connecting,
        connectionStatusLabel: 'Connecting',
        framesReceived: 0,
        clearError: true,
        clearFrame: true,
      ),
    );

    try {
      await _repository.connect(host);
    } on ViewerConnectionException catch (error) {
      emit(
        state.copyWith(
          phase: ViewerPhase.error,
          lastError: error.message,
          streamStatus: 'Connection failed',
          connectionStatus: ViewerConnectionStatus.failed,
          connectionStatusLabel: 'Failed',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: ViewerPhase.error,
          lastError: error.toString(),
          streamStatus: 'Connection failed',
          connectionStatus: ViewerConnectionStatus.failed,
          connectionStatusLabel: 'Failed',
        ),
      );
    }
  }

  /// Connects using a join payload decoded from a scanned QR code.
  Future<void> connectViaQrPayload({
    required String websocketUrl,
    String? deviceName,
    String? ipAddress,
    int? port,
  }) {
    final uri = Uri.tryParse(websocketUrl);
    final host = DiscoveredHost(
      id: '${ipAddress ?? uri?.host ?? 'qr'}:${port ?? uri?.port ?? 8080}',
      deviceName: deviceName ?? 'Peer View Host',
      ipAddress: ipAddress ?? uri?.host ?? 'unknown',
      port: port ?? uri?.port ?? 8080,
      websocketUrl: websocketUrl,
      status: HostStatus.streaming,
      lastSeen: DateTime.now(),
    );
    return connectToHost(host);
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    emit(
      state.copyWith(
        phase: ViewerPhase.disconnected,
        connectionStatus: ViewerConnectionStatus.disconnected,
        connectionStatusLabel: 'Disconnected',
        streamStatus: 'Disconnected',
        clearFrame: true,
        clearSelectedHost: true,
      ),
    );
    await scanForHosts();
  }

  void _handleHostsUpdated(List<DiscoveredHost> hosts) {
    if (state.phase == ViewerPhase.connecting ||
        state.phase == ViewerPhase.connected ||
        state.phase == ViewerPhase.streaming ||
        state.connectionStatus == ViewerConnectionStatus.reconnecting) {
      return;
    }

    emit(
      state.copyWith(
        discoveredHosts: hosts,
        phase: hosts.isEmpty ? ViewerPhase.scanning : ViewerPhase.hostsFound,
        streamStatus: hosts.isEmpty ? 'Scanning LAN...' : '${hosts.length} host(s) found',
        connectionStatusLabel: hosts.isEmpty ? 'Scanning' : 'Hosts available',
      ),
    );
  }

  void _handleConnectionEvent(ViewerConnectionEvent event) {
    switch (event) {
      case ViewerConnectingEvent():
        emit(
          state.copyWith(
            phase: ViewerPhase.connecting,
            connectionStatus: ViewerConnectionStatus.connecting,
            connectionStatusLabel: 'Connecting',
            streamStatus: 'Connecting to host...',
          ),
        );
      case ViewerConnectedEvent():
        emit(
          state.copyWith(
            phase: ViewerPhase.connected,
            connectionStatus: ViewerConnectionStatus.connected,
            connectionStatusLabel: 'Connected',
            streamStatus: 'Waiting for frames...',
            reconnectAttempt: 0,
          ),
        );
      case ViewerReconnectingEvent(:final attempt, :final maxAttempts):
        emit(
          state.copyWith(
            phase: ViewerPhase.connecting,
            connectionStatus: ViewerConnectionStatus.reconnecting,
            connectionStatusLabel: 'Reconnecting',
            streamStatus: 'Reconnecting ($attempt/$maxAttempts)...',
            reconnectAttempt: attempt,
            maxReconnectAttempts: maxAttempts,
          ),
        );
      case ViewerDisconnectedEvent(:final reason):
        if (reason == 'Disconnected by user') {
          return;
        }
        emit(
          state.copyWith(
            phase: ViewerPhase.disconnected,
            connectionStatus: ViewerConnectionStatus.disconnected,
            connectionStatusLabel: 'Disconnected',
            streamStatus: reason ?? 'Disconnected',
            clearFrame: true,
            clearSelectedHost: true,
          ),
        );
        unawaited(scanForHosts());
      case ViewerConnectionFailedEvent(:final message):
        emit(
          state.copyWith(
            phase: ViewerPhase.error,
            connectionStatus: ViewerConnectionStatus.failed,
            connectionStatusLabel: 'Failed',
            streamStatus: 'Connection failed',
            lastError: message,
            clearFrame: true,
          ),
        );
        unawaited(scanForHosts());
      case ViewerStreamEndedEvent():
        emit(
          state.copyWith(
            streamStatus: 'Stream ended',
            connectionStatusLabel: 'Stream ended',
          ),
        );
    }
  }

  void _handleFrameReceived(DecodedFrame frame) {
    emit(
      state.copyWith(
        phase: ViewerPhase.streaming,
        connectionStatus: ViewerConnectionStatus.connected,
        connectionStatusLabel: 'Streaming',
        streamStatus: 'Live',
        latestFrame: frame,
        framesReceived: frame.sequenceNumber + 1,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _hostsSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _frameSubscription?.cancel();
    await _repository.disconnect();
    await _repository.stopDiscovery();
    return super.close();
  }
}
