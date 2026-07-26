import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_connection_event.dart';

/// Coordinates discovery, connection, decoding, and playback for the viewer.
abstract interface class ViewerRepository {
  Stream<List<DiscoveredHost>> get discoveredHostsStream;

  Stream<ViewerConnectionEvent> get connectionEvents;

  Stream<DecodedFrame> get frameStream;

  bool get isScanning;

  bool get isConnected;

  Future<void> startDiscovery();

  Future<void> refreshDiscovery();

  Future<void> stopDiscovery();

  Future<void> connect(DiscoveredHost host);

  Future<void> disconnect();
}
