import 'dart:async';
import 'dart:developer' as developer;

import 'package:peer_view_2/features/screen_streaming/models/stream_log_entry.dart';
import 'package:peer_view_2/features/screen_streaming/services/stream_logger.dart';

/// In-memory logger that exposes recent entries to the host UI.
class InMemoryStreamLogger implements StreamLogger {
  InMemoryStreamLogger({this.maxEntries = 100});

  final int maxEntries;
  final List<StreamLogEntry> _entries = [];
  final StreamController<StreamLogEntry> _controller =
      StreamController<StreamLogEntry>.broadcast();

  @override
  List<StreamLogEntry> get entries => List.unmodifiable(_entries);

  @override
  Stream<StreamLogEntry> get logStream => _controller.stream;

  @override
  void info(String message) => _log(StreamLogLevel.info, message);

  @override
  void warning(String message) => _log(StreamLogLevel.warning, message);

  @override
  void error(String message, {Object? cause}) {
    final suffix = cause == null ? '' : ' ($cause)';
    _log(StreamLogLevel.error, '$message$suffix');
  }

  @override
  void clear() {
    _entries.clear();
  }

  void _log(StreamLogLevel level, String message) {
    final entry = StreamLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );

    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }

    developer.log(message, name: 'ScreenStreaming', level: _developerLevel(level));
    if (!_controller.isClosed) {
      _controller.add(entry);
    }
  }

  int _developerLevel(StreamLogLevel level) {
    return switch (level) {
      StreamLogLevel.info => 800,
      StreamLogLevel.warning => 900,
      StreamLogLevel.error => 1000,
    };
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
