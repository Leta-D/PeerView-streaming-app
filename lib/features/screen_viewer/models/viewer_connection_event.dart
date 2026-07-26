import 'package:equatable/equatable.dart';

/// WebSocket connection lifecycle events for the viewer.
enum ViewerConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

sealed class ViewerConnectionEvent extends Equatable {
  const ViewerConnectionEvent(this.timestamp);

  final DateTime timestamp;

  @override
  List<Object?> get props => [timestamp];
}

final class ViewerConnectingEvent extends ViewerConnectionEvent {
  const ViewerConnectingEvent({required DateTime timestamp, required this.url})
      : super(timestamp);

  final String url;

  @override
  List<Object?> get props => [...super.props, url];
}

final class ViewerConnectedEvent extends ViewerConnectionEvent {
  const ViewerConnectedEvent({required DateTime timestamp, required this.url})
      : super(timestamp);

  final String url;

  @override
  List<Object?> get props => [...super.props, url];
}

final class ViewerDisconnectedEvent extends ViewerConnectionEvent {
  const ViewerDisconnectedEvent({required DateTime timestamp, this.reason})
      : super(timestamp);

  final String? reason;

  @override
  List<Object?> get props => [...super.props, reason];
}

final class ViewerReconnectingEvent extends ViewerConnectionEvent {
  const ViewerReconnectingEvent({
    required DateTime timestamp,
    required this.attempt,
    required this.maxAttempts,
  }) : super(timestamp);

  final int attempt;
  final int maxAttempts;

  @override
  List<Object?> get props => [...super.props, attempt, maxAttempts];
}

final class ViewerConnectionFailedEvent extends ViewerConnectionEvent {
  const ViewerConnectionFailedEvent({
    required DateTime timestamp,
    required this.message,
    this.cause,
  }) : super(timestamp);

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [...super.props, message, cause];
}

final class ViewerStreamEndedEvent extends ViewerConnectionEvent {
  const ViewerStreamEndedEvent({required DateTime timestamp}) : super(timestamp);
}
