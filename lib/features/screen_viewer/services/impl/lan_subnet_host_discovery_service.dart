import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_exceptions.dart';
import 'package:peer_view_2/features/screen_viewer/services/host_discovery_service.dart';

/// Discovers hosts by scanning the local /24 subnet for compatible WebSocket servers.
///
/// The host does not broadcast mDNS today, so subnet probing is used instead.
/// Phase 3+: add Bonjour/NSD when the host advertises `_peer-view._tcp`.
class LanSubnetHostDiscoveryService implements HostDiscoveryService {
  LanSubnetHostDiscoveryService({
    this.probeTimeout = const Duration(milliseconds: 450),
    this.hostStaleAfter = const Duration(seconds: 20),
    this.refreshInterval = const Duration(seconds: 8),
    this.scanConcurrency = 32,
  });

  final Duration probeTimeout;
  final Duration hostStaleAfter;
  final Duration refreshInterval;
  final int scanConcurrency;

  static const _defaultConfig = StreamServerConfig();

  final StreamController<List<DiscoveredHost>> _hostsController =
      StreamController<List<DiscoveredHost>>.broadcast();

  final Map<String, DiscoveredHost> _hosts = {};
  Timer? _refreshTimer;
  Timer? _staleTimer;
  bool _isScanning = false;
  int _scanGeneration = 0;

  @override
  bool get isScanning => _isScanning;

  @override
  Stream<List<DiscoveredHost>> get discoveredHostsStream => _hostsController.stream;

  @override
  Future<void> startDiscovery({int port = 8080}) async {
    if (_isScanning) {
      await refresh(port: port);
      return;
    }

    _isScanning = true;
    _startTimers(port);
    await refresh(port: port);
  }

  void _startTimers(int port) {
    _refreshTimer?.cancel();
    _staleTimer?.cancel();

    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      unawaited(refresh(port: port));
    });

    _staleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _removeStaleHosts();
    });
  }

  @override
  Future<void> refresh({int port = 8080}) async {
    final generation = ++_scanGeneration;
    final subnets = await _resolveLocalSubnets();

    if (subnets.isEmpty) {
      throw const HostDiscoveryException('No local network interface found.');
    }

    for (final subnet in subnets) {
      if (generation != _scanGeneration) {
        return;
      }
      await _scanSubnet(subnet: subnet, port: port, generation: generation);
    }

    _emitHosts();
  }

  Future<void> _scanSubnet({
    required _Subnet subnet,
    required int port,
    required int generation,
  }) async {
    final candidates = subnet.hostAddresses.where((ip) => ip != subnet.localIp);

    await _mapConcurrent(
      candidates,
      scanConcurrency,
      (ip) async {
        if (generation != _scanGeneration) {
          return;
        }

        final host = await _probeHost(ip: ip, port: port);
        if (host != null) {
          _hosts[host.id] = host;
        }
      },
    );
  }

  Future<DiscoveredHost?> _probeHost({
    required String ip,
    required int port,
  }) async {
    final url = 'ws://$ip:$port${_defaultConfig.webSocketPath}';

    try {
      final socket = await WebSocket.connect(url).timeout(probeTimeout);
      final completer = Completer<DiscoveredHost?>();
      late StreamSubscription<dynamic> subscription;

      subscription = socket.listen(
        (message) {
          if (completer.isCompleted) {
            return;
          }

          if (message is String) {
            final host = _hostFromControlMessage(message, ip: ip, port: port);
            completer.complete(host);
            return;
          }

          if (message is List<int> && _looksLikePv2Packet(message)) {
            completer.complete(_fallbackHost(ip: ip, port: port));
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      final result = await completer.future.timeout(
        probeTimeout,
        onTimeout: () => null,
      );

      await subscription.cancel();
      await socket.close();

      return result?.copyWith(lastSeen: DateTime.now());
    } catch (_) {
      return null;
    }
  }

  DiscoveredHost? _hostFromControlMessage(
    String message, {
    required String ip,
    required int port,
  }) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] != 'stream_start') {
        return null;
      }

      final deviceName = data['client']?.toString() ?? 'Peer View Host';
      return DiscoveredHost(
        id: '$ip:$port',
        deviceName: deviceName.replaceAll('_', ' '),
        ipAddress: ip,
        port: port,
        websocketUrl: 'ws://$ip:$port${_defaultConfig.webSocketPath}',
        status: HostStatus.streaming,
        lastSeen: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  DiscoveredHost _fallbackHost({required String ip, required int port}) {
    return DiscoveredHost(
      id: '$ip:$port',
      deviceName: 'Peer View Host',
      ipAddress: ip,
      port: port,
      websocketUrl: 'ws://$ip:$port${_defaultConfig.webSocketPath}',
      status: HostStatus.available,
      lastSeen: DateTime.now(),
    );
  }

  bool _looksLikePv2Packet(List<int> bytes) {
    const magic = [0x50, 0x56, 0x32, 0x00];
    if (bytes.length < magic.length) {
      return false;
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) {
        return false;
      }
    }
    return true;
  }

  void _removeStaleHosts() {
    final now = DateTime.now();
    _hosts.removeWhere(
      (_, host) => now.difference(host.lastSeen) > hostStaleAfter,
    );
    _emitHosts();
  }

  void _emitHosts() {
    if (_hostsController.isClosed) {
      return;
    }

    final sorted = _hosts.values.toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    _hostsController.add(sorted);
  }

  Future<List<_Subnet>> _resolveLocalSubnets() async {
    final subnets = <_Subnet>[];

    for (final interface in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    )) {
      for (final address in interface.addresses) {
        if (address.isLoopback) {
          continue;
        }

        final parts = address.address.split('.');
        if (parts.length != 4) {
          continue;
        }

        final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        subnets.add(
          _Subnet(
            localIp: address.address,
            hostAddresses: List.generate(
              254,
              (index) => '$prefix.${index + 1}',
            ),
          ),
        );
      }
    }

    return subnets;
  }

  Future<void> _mapConcurrent<T>(
    Iterable<T> items,
    int concurrency,
    Future<void> Function(T item) action,
  ) async {
    final iterator = items.iterator;
    final workers = List.generate(concurrency, (_) async {
      while (iterator.moveNext()) {
        await action(iterator.current);
      }
    });
    await Future.wait(workers);
  }

  @override
  Future<void> stopDiscovery() async {
    _isScanning = false;
    _scanGeneration++;
    _refreshTimer?.cancel();
    _staleTimer?.cancel();
    _hosts.clear();
    _emitHosts();
  }

  void dispose() {
    stopDiscovery();
    _hostsController.close();
  }
}

class _Subnet {
  const _Subnet({required this.localIp, required this.hostAddresses});

  final String localIp;
  final List<String> hostAddresses;
}
