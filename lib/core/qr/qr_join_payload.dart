import 'dart:convert';

import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';

/// Encodes/decodes Peer View join payloads for QR codes.
///
/// Preferred payload is JSON:
/// `{ "type": "peer_view_join", "url": "ws://...", "name": "...", "ip": "...", "port": 8080 }`
///
/// Plain `ws://` / `wss://` URLs are also accepted for compatibility.
class QrJoinPayload {
  const QrJoinPayload({
    required this.websocketUrl,
    this.deviceName,
    this.ipAddress,
    this.port,
  });

  static const type = 'peer_view_join';

  final String websocketUrl;
  final String? deviceName;
  final String? ipAddress;
  final int? port;

  String encode() {
    return jsonEncode({
      'type': type,
      'url': websocketUrl,
      if (deviceName != null) 'name': deviceName,
      if (ipAddress != null) 'ip': ipAddress,
      if (port != null) 'port': port,
    });
  }

  static QrJoinPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('ws://') || trimmed.startsWith('wss://')) {
      return QrJoinPayload(websocketUrl: trimmed);
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final typeValue = decoded['type']?.toString();
      final url = decoded['url']?.toString();
      if (typeValue != type || url == null || url.isEmpty) {
        return null;
      }

      return QrJoinPayload(
        websocketUrl: url,
        deviceName: decoded['name']?.toString(),
        ipAddress: decoded['ip']?.toString(),
        port: decoded['port'] is int
            ? decoded['port'] as int
            : int.tryParse(decoded['port']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  DiscoveredHost toDiscoveredHost() {
    final uri = Uri.tryParse(websocketUrl);
    final resolvedIp = ipAddress ?? uri?.host ?? 'unknown';
    final resolvedPort = port ?? uri?.port ?? 8080;

    return DiscoveredHost(
      id: '$resolvedIp:$resolvedPort',
      deviceName: deviceName ?? 'Peer View Host',
      ipAddress: resolvedIp,
      port: resolvedPort,
      websocketUrl: websocketUrl,
      status: HostStatus.streaming,
      lastSeen: DateTime.now(),
    );
  }
}
