import 'package:flutter/material.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';

/// List tile for a discovered LAN host with connect action.
class HostListTile extends StatelessWidget {
  const HostListTile({
    super.key,
    required this.host,
    required this.onConnect,
    this.enabled = true,
  });

  final DiscoveredHost host;
  final VoidCallback onConnect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(host.status, colorScheme),
          child: Icon(
            _statusIcon(host.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(host.deviceName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(host.ipAddress),
            Text(
              host.websocketUrl,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: enabled ? onConnect : null,
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Color _statusColor(HostStatus status, ColorScheme colorScheme) {
    return switch (status) {
      HostStatus.streaming => Colors.green,
      HostStatus.available => colorScheme.primary,
      HostStatus.unavailable => Colors.grey,
    };
  }

  IconData _statusIcon(HostStatus status) {
    return switch (status) {
      HostStatus.streaming => Icons.sensors,
      HostStatus.available => Icons.wifi,
      HostStatus.unavailable => Icons.wifi_off,
    };
  }
}
