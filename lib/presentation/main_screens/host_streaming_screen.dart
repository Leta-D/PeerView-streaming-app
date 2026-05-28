import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_cubit.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_state.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:peer_view_2/presentation/widgets/host_qr_sheet.dart';
import 'package:peer_view_2/presentation/widgets/stream_preview_window.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

/// Host-side screen for starting a local WebSocket stream.
class HostStreamingScreen extends StatefulWidget {
  const HostStreamingScreen({super.key});

  @override
  State<HostStreamingScreen> createState() => _HostStreamingScreenState();
}

class _HostStreamingScreenState extends State<HostStreamingScreen> {
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScreenStreamingCubit, ScreenStreamingState>(
      listenWhen: (previous, current) => previous.streaming && !current.streaming,
      listener: (context, state) {
        if (_showPreview) {
          setState(() => _showPreview = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Host Streaming'),
          actions: [
            BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
              builder: (context, state) {
                final url = state.websocketUrl;
                final canShowQr = url != null && url.isNotEmpty;

                return IconButton(
                  tooltip: 'Show join QR code',
                  onPressed: canShowQr
                      ? () => HostQrSheet.show(
                            context,
                            websocketUrl: url,
                            hostIpAddress: state.hostIpAddress,
                            port: state.port,
                          )
                      : null,
                  icon: const Icon(Icons.qr_code_2_rounded),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
                  builder: (context, state) {
                    final isLive =
                        state.status == ScreenStreamingStatus.streaming ||
                        state.status == ScreenStreamingStatus.clientConnected;
                    final isBusy =
                        state.status == ScreenStreamingStatus.starting ||
                        state.status == ScreenStreamingStatus.stopping;

                    return FadeSlideIn(
                      child: AppCard(
                        accentBorder: state.streaming,
                        breathe: isLive,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Status',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Spacer(),
                                if (isLive) ...[
                                  const LiveBadge(),
                                  const SizedBox(width: 8),
                                ],
                                AppStatusChip(
                                  label: _statusLabel(state.status),
                                  color: _statusColor(state.status),
                                  pulse: isLive || isBusy,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AnimatedStatusText(
                              text: _statusLabel(state.status),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (isBusy) ...[
                              const SizedBox(height: 14),
                              const LinearProgressIndicator(
                                minHeight: 3,
                                borderRadius: BorderRadius.all(Radius.circular(999)),
                              ),
                            ],
                            const SizedBox(height: 18),
                            AppInfoRow(
                              label: 'Host IP',
                              value: state.hostIpAddress ?? 'Detecting...',
                              selectable: true,
                            ),
                            AppInfoRow(label: 'Port', value: '${state.port}'),
                            AppInfoRow(
                              label: 'Path',
                              value: context
                                  .read<ScreenStreamingCubit>()
                                  .serverConfig
                                  .webSocketPath,
                            ),
                            AppInfoRow(
                              label: 'URL',
                              value: state.websocketUrl ?? 'Detecting...',
                              selectable: true,
                            ),
                            AppInfoRow(
                              label: 'Clients',
                              value: '${state.connectedClientCount}',
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: state.streaming
                                  ? Column(
                                      children: [
                                        AppInfoRow(
                                          label: 'Captured',
                                          value: '${state.framesCaptured}',
                                        ),
                                        AppInfoRow(
                                          label: 'Broadcast',
                                          value: '${state.framesBroadcast}',
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (state.lastError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                state.lastError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.error),
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSecondaryButton(
                          label: _showPreview ? 'Hide Preview' : 'Show Preview',
                          icon: _showPreview
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          onPressed: () {
                            setState(() => _showPreview = !_showPreview);
                          },
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1,
                                child: child,
                              ),
                            );
                          },
                          child: !_showPreview
                              ? const SizedBox.shrink(key: ValueKey('preview-hidden'))
                              : Padding(
                                  key: const ValueKey('preview-visible'),
                                  padding: const EdgeInsets.only(top: 12),
                                  child: AppCard(
                                    breathe: true,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const AppSectionHeader(
                                          title: 'Live Preview',
                                          subtitle:
                                              'Local capture preview while streaming',
                                          trailing: LiveBadge(),
                                        ),
                                        const SizedBox(height: 14),
                                        StreamPreviewWindow(
                                          previewStream: context
                                              .read<ScreenStreamingCubit>()
                                              .previewStream,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Start Streaming',
                            icon: Icons.play_arrow_rounded,
                            onPressed: state.canStart
                                ? () => context
                                    .read<ScreenStreamingCubit>()
                                    .startStreaming()
                                : null,
                            isLoading:
                                state.status == ScreenStreamingStatus.starting,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Stop',
                            icon: Icons.stop_rounded,
                            onPressed: state.canStop
                                ? () => context
                                    .read<ScreenStreamingCubit>()
                                    .stopStreaming()
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
                  builder: (context, state) {
                    final url = state.websocketUrl;
                    final canShowQr = url != null && url.isNotEmpty;

                    return AppSecondaryButton(
                      label: 'Show Join QR',
                      icon: Icons.qr_code_2_rounded,
                      onPressed: canShowQr
                          ? () => HostQrSheet.show(
                                context,
                                websocketUrl: url,
                                hostIpAddress: state.hostIpAddress,
                                port: state.port,
                              )
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<ScreenStreamingCubit, ScreenStreamingState>(
                  builder: (context, state) {
                    return FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: 'Recent Events',
                              subtitle: 'Capture, encode, and broadcast activity',
                            ),
                            const SizedBox(height: 12),
                            StreamEventLog(entries: state.recentLogs),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Clients can join with the connection URL or by scanning the join QR code.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
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

  Color _statusColor(ScreenStreamingStatus status) {
    return switch (status) {
      ScreenStreamingStatus.streaming ||
      ScreenStreamingStatus.clientConnected =>
        AppColors.success,
      ScreenStreamingStatus.starting ||
      ScreenStreamingStatus.waitingForClients ||
      ScreenStreamingStatus.stopping =>
        AppColors.warning,
      ScreenStreamingStatus.error => AppColors.error,
      ScreenStreamingStatus.initial || ScreenStreamingStatus.stopped =>
        AppColors.primary,
    };
  }
}
