import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_cubit.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_state.dart';
import 'package:peer_view_2/presentation/widgets/stream_preview_window.dart';

/// Host-side screen for starting a local WebSocket stream.
class HostStreamingScreen extends StatelessWidget {
  const HostStreamingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Streaming'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
              builder: (context, state) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusLabel(state.status),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Host IP',
                          value: state.hostIpAddress ?? 'Detecting...',
                        ),
                        _InfoRow(label: 'Port', value: '${state.port}'),
                        _InfoRow(
                          label: 'Connection URL',
                          value: state.websocketUrl ?? 'Detecting...',
                        ),
                        _InfoRow(
                          label: 'Connected clients',
                          value: '${state.connectedClientCount}',
                        ),
                        if (state.streaming) ...[
                          const SizedBox(height: 8),
                          Text('Frames captured: ${state.framesCaptured}'),
                          Text('Frames broadcast: ${state.framesBroadcast}'),
                        ],
                        if (state.lastError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.lastError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
              builder: (context, state) {
                if (!state.streaming) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Preview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        StreamPreviewWindow(
                          previewStream: context
                              .read<ScreenStreamingCubit>()
                              .previewStream,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
              builder: (context, state) {
                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: state.canStart
                            ? () => context
                                  .read<ScreenStreamingCubit>()
                                  .startStreaming()
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Streaming'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.canStop
                            ? () => context
                                  .read<ScreenStreamingCubit>()
                                  .stopStreaming()
                            : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Streaming'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
              builder: (context, state) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Events',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        StreamEventLog(entries: state.recentLogs),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Clients on the same Wi‑Fi or hotspot can connect using the Connection URL above. '
              'Phase 2 will add the viewer application.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ScreenStreamingStatus status) {
    return switch (status) {
      ScreenStreamingStatus.initial => 'Ready',
      ScreenStreamingStatus.starting => 'Starting...',
      ScreenStreamingStatus.waitingForClients => 'Waiting for clients',
      ScreenStreamingStatus.clientConnected => 'Client connected',
      ScreenStreamingStatus.streaming => 'Streaming',
      ScreenStreamingStatus.stopping => 'Stopping...',
      ScreenStreamingStatus.stopped => 'Stopped',
      ScreenStreamingStatus.error => 'Error',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
