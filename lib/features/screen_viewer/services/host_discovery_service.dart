import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';

/// Discovers compatible streaming hosts on the local network.
abstract interface class HostDiscoveryService {
  /// Whether a discovery scan is currently running.
  bool get isScanning;

  /// Emits the latest list of discovered hosts whenever it changes.
  Stream<List<DiscoveredHost>> get discoveredHostsStream;

  /// Starts continuous LAN discovery and periodic refresh.
  Future<void> startDiscovery({
    int port = 8080,
    String webSocketPath = '/stream',
  });

  /// Performs a one-shot refresh of discovered hosts.
  Future<void> refresh({
    int port = 8080,
    String webSocketPath = '/stream',
  });

  /// Stops discovery and clears ephemeral scan state.
  Future<void> stopDiscovery();
}
