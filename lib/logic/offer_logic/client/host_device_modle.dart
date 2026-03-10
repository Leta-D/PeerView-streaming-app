class HostDevice {
  final String name;
  final String ip;
  final int port;
  final DateTime lastSeen;

  HostDevice({
    required this.name,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });
}
