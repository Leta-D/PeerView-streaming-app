import 'package:equatable/equatable.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_log_entry.dart';

/// Lifecycle status for the host streaming feature.
enum ScreenStreamingStatus {
  initial,
  starting,
  waitingForClients,
  clientConnected,
  streaming,
  stopping,
  stopped,
  error,
}

/// UI-facing state for the host streaming screen.
class ScreenStreamingState extends Equatable {
  const ScreenStreamingState({
    this.status = ScreenStreamingStatus.initial,
    this.serverRunning = false,
    this.streaming = false,
    this.connectedClientCount = 0,
    this.hostIpAddress,
    this.port = 8080,
    this.websocketUrl,
    this.lastError,
    this.recentLogs = const [],
    this.framesCaptured = 0,
    this.framesBroadcast = 0,
  });

  final ScreenStreamingStatus status;
  final bool serverRunning;
  final bool streaming;
  final int connectedClientCount;
  final String? hostIpAddress;
  final int port;
  final String? websocketUrl;
  final String? lastError;
  final List<StreamLogEntry> recentLogs;
  final int framesCaptured;
  final int framesBroadcast;

  bool get canStart =>
      status == ScreenStreamingStatus.initial ||
      status == ScreenStreamingStatus.stopped ||
      status == ScreenStreamingStatus.error;

  bool get canStop =>
      status == ScreenStreamingStatus.starting ||
      status == ScreenStreamingStatus.waitingForClients ||
      status == ScreenStreamingStatus.clientConnected ||
      status == ScreenStreamingStatus.streaming;

  ScreenStreamingState copyWith({
    ScreenStreamingStatus? status,
    bool? serverRunning,
    bool? streaming,
    int? connectedClientCount,
    String? hostIpAddress,
    int? port,
    String? websocketUrl,
    String? lastError,
    List<StreamLogEntry>? recentLogs,
    int? framesCaptured,
    int? framesBroadcast,
    bool clearError = false,
  }) {
    return ScreenStreamingState(
      status: status ?? this.status,
      serverRunning: serverRunning ?? this.serverRunning,
      streaming: streaming ?? this.streaming,
      connectedClientCount: connectedClientCount ?? this.connectedClientCount,
      hostIpAddress: hostIpAddress ?? this.hostIpAddress,
      port: port ?? this.port,
      websocketUrl: websocketUrl ?? this.websocketUrl,
      lastError: clearError ? null : (lastError ?? this.lastError),
      recentLogs: recentLogs ?? this.recentLogs,
      framesCaptured: framesCaptured ?? this.framesCaptured,
      framesBroadcast: framesBroadcast ?? this.framesBroadcast,
    );
  }

  @override
  List<Object?> get props => [
        status,
        serverRunning,
        streaming,
        connectedClientCount,
        hostIpAddress,
        port,
        websocketUrl,
        lastError,
        recentLogs,
        framesCaptured,
        framesBroadcast,
      ];
}
