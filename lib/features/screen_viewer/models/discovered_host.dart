import 'package:equatable/equatable.dart';

/// Availability of a discovered host on the LAN.
enum HostStatus {
  available,
  streaming,
  unavailable,
}

/// A compatible host found on the local network.
class DiscoveredHost extends Equatable {
  const DiscoveredHost({
    required this.id,
    required this.deviceName,
    required this.ipAddress,
    required this.port,
    required this.websocketUrl,
    required this.status,
    required this.lastSeen,
  });

  final String id;
  final String deviceName;
  final String ipAddress;
  final int port;
  final String websocketUrl;
  final HostStatus status;
  final DateTime lastSeen;

  DiscoveredHost copyWith({
    String? deviceName,
    HostStatus? status,
    DateTime? lastSeen,
  }) {
    return DiscoveredHost(
      id: id,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress,
      port: port,
      websocketUrl: websocketUrl,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceName,
        ipAddress,
        port,
        websocketUrl,
        status,
        lastSeen,
      ];
}
