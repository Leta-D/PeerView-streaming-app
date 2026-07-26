import 'package:equatable/equatable.dart';

/// Network information exposed to clients for connecting to the host.
class HostNetworkInfo extends Equatable {
  const HostNetworkInfo({
    required this.hostIpAddress,
    required this.port,
    required this.websocketUrl,
    this.interfaceName,
  });

  final String hostIpAddress;
  final int port;
  final String websocketUrl;
  final String? interfaceName;

  @override
  List<Object?> get props => [hostIpAddress, port, websocketUrl, interfaceName];
}
