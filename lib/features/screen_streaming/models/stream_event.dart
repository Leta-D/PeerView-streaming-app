import 'package:equatable/equatable.dart';

/// High-level lifecycle events emitted by the streaming pipeline.
sealed class StreamEvent extends Equatable {
  const StreamEvent(this.timestamp);

  final DateTime timestamp;

  @override
  List<Object?> get props => [timestamp];
}

final class StreamServerStartedEvent extends StreamEvent {
  const StreamServerStartedEvent({
    required DateTime timestamp,
    required this.port,
    required this.websocketUrl,
  }) : super(timestamp);

  final int port;
  final String websocketUrl;

  @override
  List<Object?> get props => [...super.props, port, websocketUrl];
}

final class StreamServerStoppedEvent extends StreamEvent {
  const StreamServerStoppedEvent({required DateTime timestamp}) : super(timestamp);
}

final class StreamClientConnectedEvent extends StreamEvent {
  const StreamClientConnectedEvent({
    required DateTime timestamp,
    required this.clientId,
    required this.connectedClientCount,
  }) : super(timestamp);

  final String clientId;
  final int connectedClientCount;

  @override
  List<Object?> get props => [...super.props, clientId, connectedClientCount];
}

final class StreamClientDisconnectedEvent extends StreamEvent {
  const StreamClientDisconnectedEvent({
    required DateTime timestamp,
    required this.clientId,
    required this.connectedClientCount,
  }) : super(timestamp);

  final String clientId;
  final int connectedClientCount;

  @override
  List<Object?> get props => [...super.props, clientId, connectedClientCount];
}

final class StreamFrameCapturedEvent extends StreamEvent {
  const StreamFrameCapturedEvent({
    required DateTime timestamp,
    required this.sequenceNumber,
  }) : super(timestamp);

  final int sequenceNumber;

  @override
  List<Object?> get props => [...super.props, sequenceNumber];
}

final class StreamFrameEncodedEvent extends StreamEvent {
  const StreamFrameEncodedEvent({
    required DateTime timestamp,
    required this.sequenceNumber,
    required this.payloadBytes,
  }) : super(timestamp);

  final int sequenceNumber;
  final int payloadBytes;

  @override
  List<Object?> get props => [...super.props, sequenceNumber, payloadBytes];
}

final class StreamFrameBroadcastEvent extends StreamEvent {
  const StreamFrameBroadcastEvent({
    required DateTime timestamp,
    required this.sequenceNumber,
    required this.recipientCount,
  }) : super(timestamp);

  final int sequenceNumber;
  final int recipientCount;

  @override
  List<Object?> get props => [...super.props, sequenceNumber, recipientCount];
}

final class StreamErrorEvent extends StreamEvent {
  const StreamErrorEvent({
    required DateTime timestamp,
    required this.message,
    this.cause,
  }) : super(timestamp);

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [...super.props, message, cause];
}

final class StreamNetworkChangedEvent extends StreamEvent {
  const StreamNetworkChangedEvent({
    required DateTime timestamp,
    required this.hostIpAddress,
    required this.websocketUrl,
  }) : super(timestamp);

  final String hostIpAddress;
  final String websocketUrl;

  @override
  List<Object?> get props => [...super.props, hostIpAddress, websocketUrl];
}
