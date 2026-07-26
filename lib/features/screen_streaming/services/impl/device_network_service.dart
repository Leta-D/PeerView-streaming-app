import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:peer_view_2/features/screen_streaming/models/host_network_info.dart';
import 'package:peer_view_2/features/screen_streaming/services/network_service.dart';

/// Resolves the host device's local IPv4 address for client connection URLs.
class DeviceNetworkService implements NetworkService {
  DeviceNetworkService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<HostNetworkInfo> getHostNetworkInfo({int port = 8080}) async {
    final hostIp = await _resolveLocalIpAddress();
    return _buildInfo(hostIp, port);
  }

  @override
  Stream<HostNetworkInfo> watchNetworkInfo({int port = 8080}) async* {
    yield await getHostNetworkInfo(port: port);

    await for (final _ in _connectivity.onConnectivityChanged) {
      yield await getHostNetworkInfo(port: port);
    }
  }

  HostNetworkInfo _buildInfo(String hostIp, int port) {
    return HostNetworkInfo(
      hostIpAddress: hostIp,
      port: port,
      websocketUrl: 'ws://$hostIp:$port/stream',
    );
  }

  Future<String> _resolveLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    const preferredNames = [
      'wlan0',
      'ap0',
      'swlan0',
      'eth0',
      'en0',
    ];

    for (final name in preferredNames) {
      for (final interface in interfaces) {
        if (interface.name.toLowerCase() == name) {
          final address = _firstUsableAddress(interface);
          if (address != null) {
            return address;
          }
        }
      }
    }

    for (final interface in interfaces) {
      final address = _firstUsableAddress(interface);
      if (address != null) {
        return address;
      }
    }

    return '127.0.0.1';
  }

  String? _firstUsableAddress(NetworkInterface interface) {
    for (final address in interface.addresses) {
      if (!address.isLoopback) {
        return address.address;
      }
    }
    return null;
  }
}
