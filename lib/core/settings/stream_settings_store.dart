import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists host/client stream connection settings (port + WebSocket path).
class StreamSettingsStore {
  StreamSettingsStore(this._prefs) {
    _config = _readFromPrefs();
  }

  static const defaultPort = 8080;
  static const defaultPath = '/stream';

  static const _portKey = 'stream_port';
  static const _pathKey = 'stream_path';

  final SharedPreferences _prefs;
  late StreamServerConfig _config;

  /// Latest in-memory settings (defaults until first load/save).
  StreamServerConfig get config => _config;

  Future<StreamServerConfig> load() async {
    _config = _readFromPrefs();
    return _config;
  }

  Future<void> save({required int port, required String webSocketPath}) async {
    final normalized = StreamServerConfig(
      port: _clampPort(port),
      webSocketPath: normalizePath(webSocketPath),
    );

    await _prefs.setInt(_portKey, normalized.port);
    await _prefs.setString(_pathKey, normalized.webSocketPath);
    _config = normalized;
  }

  Future<void> resetToDefaults() => save(
        port: defaultPort,
        webSocketPath: defaultPath,
      );

  StreamServerConfig _readFromPrefs() {
    return StreamServerConfig(
      port: _clampPort(_prefs.getInt(_portKey) ?? defaultPort),
      webSocketPath: normalizePath(
        _prefs.getString(_pathKey) ?? defaultPath,
      ),
    );
  }

  /// Ensures path starts with `/` and has no trailing slash (except root).
  static String normalizePath(String raw) {
    var path = raw.trim();
    if (path.isEmpty) {
      return defaultPath;
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  static int _clampPort(int port) {
    if (port < 1 || port > 65535) {
      return defaultPort;
    }
    return port;
  }
}
