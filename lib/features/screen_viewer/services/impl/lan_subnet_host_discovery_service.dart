import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/features/screen_viewer/models/viewer_exceptions.dart';
import 'package:peer_view_2/features/screen_viewer/services/host_discovery_service.dart';

/// Discovers hosts by scanning the local /24 subnet for compatible servers.
///
/// Uses a fast HTTP identity probe first, then falls back to a short WebSocket
/// handshake when needed.
class LanSubnetHostDiscoveryService implements HostDiscoveryService {
  LanSubnetHostDiscoveryService({
    this.httpProbeTimeout = const Duration(milliseconds: 700),
    this.wsProbeTimeout = const Duration(milliseconds: 1200),
    this.hostStaleAfter = const Duration(seconds: 25),
    this.refreshInterval = const Duration(seconds: 8),
    this.scanConcurrency = 24,
  });

  final Duration httpProbeTimeout;
  final Duration wsProbeTimeout;
  final Duration hostStaleAfter;
  final Duration refreshInterval;
  final int scanConcurrency;

  final StreamController<List<DiscoveredHost>> _hostsController =
      StreamController<List<DiscoveredHost>>.broadcast();

  final Map<String, DiscoveredHost> _hosts = {};
  Timer? _refreshTimer;
  Timer? _staleTimer;
  bool _isScanning = false;
  int _scanGeneration = 0;
  int _activePort = 8080;
  String _activePath = '/stream';

  @override
  bool get isScanning => _isScanning;

  @override
  Stream<List<DiscoveredHost>> get discoveredHostsStream => _hostsController.stream;

  @override
  Future<void> startDiscovery({
    int port = 8080,
    String webSocketPath = '/stream',
  }) async {
    _activePort = port;
    _activePath = webSocketPath;

    if (_isScanning) {
      await refresh(port: port, webSocketPath: webSocketPath);
      return;
    }

    _isScanning = true;
    _startTimers();
    await refresh(port: port, webSocketPath: webSocketPath);
  }

  void _startTimers() {
    _refreshTimer?.cancel();
    _staleTimer?.cancel();

    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      unawaited(refresh(port: _activePort, webSocketPath: _activePath));
    });

    _staleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _removeStaleHosts();
    });
  }

  @override
  Future<void> refresh({
    int port = 8080,
    String webSocketPath = '/stream',
  }) async {
    _activePort = port;
    _activePath = webSocketPath;

    final generation = ++_scanGeneration;
    final subnets = await _resolveLocalSubnets();

    if (subnets.isEmpty) {
      throw const HostDiscoveryException('No local network interface found.');
    }

    for (final subnet in subnets) {
      if (generation != _scanGeneration) {
        return;
      }
      await _scanSubnet(
        subnet: subnet,
        port: port,
        webSocketPath: webSocketPath,
        generation: generation,
      );
    }

    _emitHosts();
  }

  Future<void> _scanSubnet({
    required _Subnet subnet,
    required int port,
    required String webSocketPath,
    required int generation,
  }) async {
    final candidates =
        subnet.hostAddresses.where((ip) => ip != subnet.localIp).toList();

    await _mapConcurrent(
      candidates,
      scanConcurrency,
      (ip) async {
        if (generation != _scanGeneration) {
          return;
        }

        final host = await _probeHost(
          ip: ip,
          port: port,
          webSocketPath: webSocketPath,
        );
        if (host != null && generation == _scanGeneration) {
          _hosts[host.id] = host;
          _emitHosts();
        }
      },
    );
  }

  Future<DiscoveredHost?> _probeHost({
    required String ip,
    required int port,
    required String webSocketPath,
  }) async {
    final httpHost = await _probeHttp(
      ip: ip,
      port: port,
      webSocketPath: webSocketPath,
    );
    if (httpHost != null) {
      return httpHost;
    }

    return _probeWebSocket(
      ip: ip,
      port: port,
      webSocketPath: webSocketPath,
    );
  }

  Future<DiscoveredHost?> _probeHttp({
    required String ip,
    required int port,
    required String webSocketPath,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = httpProbeTimeout
      ..idleTimeout = httpProbeTimeout;

    try {
      final uri = Uri(
        scheme: 'http',
        host: ip,
        port: port,
        path: webSocketPath,
      );
      final request = await client.getUrl(uri).timeout(httpProbeTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(httpProbeTimeout);
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join().timeout(httpProbeTimeout);
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic> || data['type'] != 'peer_view_host') {
        return null;
      }

      final deviceName = data['client']?.toString() ?? 'Peer View Host';
      return DiscoveredHost(
        id: '$ip:$port$webSocketPath',
        deviceName: deviceName.replaceAll('_', ' '),
        ipAddress: ip,
        port: port,
        websocketUrl: 'ws://$ip:$port$webSocketPath',
        status: HostStatus.streaming,
        lastSeen: DateTime.now(),
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<DiscoveredHost?> _probeWebSocket({
    required String ip,
    required int port,
    required String webSocketPath,
  }) async {
    final url = 'ws://$ip:$port$webSocketPath';

    try {
      final socket = await WebSocket.connect(url).timeout(wsProbeTimeout);
      final completer = Completer<DiscoveredHost?>();
      late StreamSubscription<dynamic> subscription;

      subscription = socket.listen(
        (message) {
          if (completer.isCompleted) {
            return;
          }

          if (message is String) {
            final host = _hostFromControlMessage(
              message,
              ip: ip,
              port: port,
              webSocketPath: webSocketPath,
            );
            completer.complete(host);
            return;
          }

          if (message is List<int> && _looksLikePv2Packet(message)) {
            completer.complete(
              _fallbackHost(ip: ip, port: port, webSocketPath: webSocketPath),
            );
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
        wsProbeTimeout,
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
    required String webSocketPath,
  }) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] != 'stream_start') {
        return null;
      }

      final deviceName = data['client']?.toString() ?? 'Peer View Host';
      return DiscoveredHost(
        id: '$ip:$port$webSocketPath',
        deviceName: deviceName.replaceAll('_', ' '),
        ipAddress: ip,
        port: port,
        websocketUrl: 'ws://$ip:$port$webSocketPath',
        status: HostStatus.streaming,
        lastSeen: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  DiscoveredHost _fallbackHost({
    required String ip,
    required int port,
    required String webSocketPath,
  }) {
    return DiscoveredHost(
      id: '$ip:$port$webSocketPath',
      deviceName: 'Peer View Host',
      ipAddress: ip,
      port: port,
      websocketUrl: 'ws://$ip:$port$webSocketPath',
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
    final before = _hosts.length;
    _hosts.removeWhere(
      (_, host) => now.difference(host.lastSeen) > hostStaleAfter,
    );
    if (_hosts.length != before) {
      _emitHosts();
    }
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

  /// Safe concurrent map that does not share a mutable iterator across workers.
  Future<void> _mapConcurrent<T>(
    List<T> items,
    int concurrency,
    Future<void> Function(T item) action,
  ) async {
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        if (nextIndex >= items.length) {
          return;
        }
        final index = nextIndex++;
        await action(items[index]);
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, items.isEmpty ? 1 : items.length),
      (_) => worker(),
    );
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
