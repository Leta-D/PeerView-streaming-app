import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_cubit.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_state.dart';
import 'package:peer_view_2/presentation/widgets/host_list_tile.dart';
import 'package:peer_view_2/presentation/widgets/live_stream_viewer.dart';

/// Viewer screen for discovering hosts and watching a live LAN stream.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ViewerCubit>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewerCubit, ViewerState>(
      builder: (context, state) {
        if (state.isLiveViewVisible) {
          return Scaffold(
            body: LiveStreamViewer(
              frame: state.latestFrame,
              connectionStatusLabel: state.connectionStatusLabel,
              streamStatus: state.streamStatus,
              onDisconnect: () => context.read<ViewerCubit>().disconnect(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Viewer'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<ViewerCubit>().scanForHosts(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                _StatusCard(state: state),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      state.canScan || state.phase == ViewerPhase.scanning
                      ? () => context.read<ViewerCubit>().scanForHosts()
                      : null,
                  icon: state.phase == ViewerPhase.scanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    state.phase == ViewerPhase.scanning
                        ? 'Scanning...'
                        : 'Scan for Hosts',
                  ),
                ),
                if (state.canDisconnect) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.read<ViewerCubit>().disconnect(),
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Discovered Hosts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (state.phase == ViewerPhase.scanning &&
                    state.discoveredHosts.isEmpty)
                  const Center(child: Text('Searching the local network...'))
                else if (state.discoveredHosts.isEmpty)
                  const Text(
                    'No hosts found yet. Make sure the host is streaming on the same Wi‑Fi or hotspot.',
                  )
                else
                  ...state.discoveredHosts.map(
                    (host) => HostListTile(
                      host: host,
                      enabled: state.phase != ViewerPhase.connecting,
                      onConnect: () =>
                          context.read<ViewerCubit>().connectToHost(host),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _phaseLabel(state.phase),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Connection: ${state.connectionStatusLabel}'),
            Text('Stream: ${state.streamStatus}'),
            if (state.selectedHost != null) ...[
              const SizedBox(height: 8),
              Text('Selected: ${state.selectedHost!.deviceName}'),
              Text(state.selectedHost!.websocketUrl),
            ],
            if (state.framesReceived > 0)
              Text('Frames received: ${state.framesReceived}'),
            if (state.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                state.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _phaseLabel(ViewerPhase phase) {
    return switch (phase) {
      ViewerPhase.initial => 'Ready',
      ViewerPhase.scanning => 'Scanning',
      ViewerPhase.hostsFound => 'Hosts Found',
      ViewerPhase.connecting => 'Connecting',
      ViewerPhase.connected => 'Connected',
      ViewerPhase.streaming => 'Streaming',
      ViewerPhase.disconnected => 'Disconnected',
      ViewerPhase.error => 'Error',
    };
  }
}
