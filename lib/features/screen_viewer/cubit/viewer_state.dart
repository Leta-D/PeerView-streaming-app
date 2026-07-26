import 'package:equatable/equatable.dart';
import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_connection_event.dart';

/// High-level viewer lifecycle phases for the UI.
enum ViewerPhase {
  initial,
  scanning,
  hostsFound,
  connecting,
  connected,
  streaming,
  disconnected,
  error,
}

/// UI-facing viewer state coordinated by [ViewerCubit].
class ViewerState extends Equatable {
  const ViewerState({
    this.phase = ViewerPhase.initial,
    this.discoveredHosts = const [],
    this.selectedHost,
    this.connectionStatus = ViewerConnectionStatus.disconnected,
    this.streamStatus = 'Idle',
    this.connectionStatusLabel = 'Disconnected',
    this.latestFrame,
    this.lastError,
    this.reconnectAttempt = 0,
    this.maxReconnectAttempts = 5,
    this.framesReceived = 0,
  });

  final ViewerPhase phase;
  final List<DiscoveredHost> discoveredHosts;
  final DiscoveredHost? selectedHost;
  final ViewerConnectionStatus connectionStatus;
  final String streamStatus;
  final String connectionStatusLabel;
  final DecodedFrame? latestFrame;
  final String? lastError;
  final int reconnectAttempt;
  final int maxReconnectAttempts;
  final int framesReceived;

  bool get canScan =>
      phase == ViewerPhase.initial ||
      phase == ViewerPhase.hostsFound ||
      phase == ViewerPhase.disconnected ||
      phase == ViewerPhase.error;

  bool get canDisconnect =>
      phase == ViewerPhase.connecting ||
      phase == ViewerPhase.connected ||
      phase == ViewerPhase.streaming ||
      connectionStatus == ViewerConnectionStatus.reconnecting;

  bool get isLiveViewVisible =>
      phase == ViewerPhase.connected ||
      phase == ViewerPhase.streaming ||
      connectionStatus == ViewerConnectionStatus.reconnecting;

  ViewerState copyWith({
    ViewerPhase? phase,
    List<DiscoveredHost>? discoveredHosts,
    DiscoveredHost? selectedHost,
    ViewerConnectionStatus? connectionStatus,
    String? streamStatus,
    String? connectionStatusLabel,
    DecodedFrame? latestFrame,
    String? lastError,
    int? reconnectAttempt,
    int? maxReconnectAttempts,
    int? framesReceived,
    bool clearError = false,
    bool clearFrame = false,
    bool clearSelectedHost = false,
  }) {
    return ViewerState(
      phase: phase ?? this.phase,
      discoveredHosts: discoveredHosts ?? this.discoveredHosts,
      selectedHost: clearSelectedHost ? null : (selectedHost ?? this.selectedHost),
      connectionStatus: connectionStatus ?? this.connectionStatus,
      streamStatus: streamStatus ?? this.streamStatus,
      connectionStatusLabel: connectionStatusLabel ?? this.connectionStatusLabel,
      latestFrame: clearFrame ? null : (latestFrame ?? this.latestFrame),
      lastError: clearError ? null : (lastError ?? this.lastError),
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      framesReceived: framesReceived ?? this.framesReceived,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        discoveredHosts,
        selectedHost,
        connectionStatus,
        streamStatus,
        connectionStatusLabel,
        latestFrame?.sequenceNumber,
        lastError,
        reconnectAttempt,
        maxReconnectAttempts,
        framesReceived,
      ];
}
