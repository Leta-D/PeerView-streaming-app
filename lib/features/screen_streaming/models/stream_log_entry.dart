import 'package:equatable/equatable.dart';

enum StreamLogLevel { info, warning, error }

/// Structured log entry shown in the host UI and debug output.
class StreamLogEntry extends Equatable {
  const StreamLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final StreamLogLevel level;
  final String message;

  @override
  List<Object?> get props => [timestamp, level, message];
}
