import 'package:flutter/material.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/features/screen_viewer/models/discovered_host.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

/// List tile for a discovered LAN host with connect action.
class HostListTile extends StatelessWidget {
  const HostListTile({
    super.key,
    required this.host,
    required this.onConnect,
    this.enabled = true,
    this.index = 0,
  });

  final DiscoveredHost host;
  final VoidCallback onConnect;
  final bool enabled;
  final int index;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 40 * index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconBadge(
                icon: _statusIcon(host.status),
                size: 48,
                iconSize: 22,
                color: _statusColor(host.status),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.deviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      host.ipAddress,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      host.websocketUrl,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    AppStatusChip(
                      label: _statusLabel(host.status),
                      color: _statusColor(host.status),
                      pulse: host.status == HostStatus.streaming,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: enabled ? onConnect : null,
                child: const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(HostStatus status) {
    return switch (status) {
      HostStatus.streaming => AppColors.surface,
      HostStatus.available => AppColors.primary,
      HostStatus.unavailable => AppColors.textMuted,
    };
  }

  IconData _statusIcon(HostStatus status) {
    return switch (status) {
      HostStatus.streaming => Icons.sensors_rounded,
      HostStatus.available => Icons.wifi_rounded,
      HostStatus.unavailable => Icons.wifi_off_rounded,
    };
  }

  String _statusLabel(HostStatus status) {
    return switch (status) {
      HostStatus.streaming => 'Streaming',
      HostStatus.available => 'Available',
      HostStatus.unavailable => 'Unavailable',
    };
  }
}
