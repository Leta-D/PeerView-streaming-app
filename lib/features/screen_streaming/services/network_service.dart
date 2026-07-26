import 'package:peer_view_2/features/screen_streaming/models/host_network_info.dart';

/// Provides host network information for client connection URLs.
abstract interface class NetworkService {
  /// Reads the current local IPv4 address and builds the WebSocket URL.
  Future<HostNetworkInfo> getHostNetworkInfo({int port = 8080});

  /// Emits updated network information when connectivity changes.
  Stream<HostNetworkInfo> watchNetworkInfo({int port = 8080});
}
