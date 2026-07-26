import 'package:peer_view_2/features/screen_streaming/models/stream_log_entry.dart';

/// Centralized logging for the host streaming feature.
abstract interface class StreamLogger {
  /// Recent log entries for the host UI.
  List<StreamLogEntry> get entries;

  /// Stream of new log entries.
  Stream<StreamLogEntry> get logStream;

  void info(String message);

  void warning(String message);

  void error(String message, {Object? cause});

  void clear();
}
