import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_cubit.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_state.dart';
import 'package:peer_view_2/presentation/main_screens/qr_scanner_screen.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:peer_view_2/presentation/widgets/host_list_tile.dart';
import 'package:peer_view_2/presentation/widgets/live_stream_viewer.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

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

  Future<void> _scanQrAndJoin() async {
    final payload = await QrScannerScreen.open(context);
    if (!mounted || payload == null) {
      return;
    }

    await context.read<ViewerCubit>().connectViaQrPayload(
      websocketUrl: payload.websocketUrl,
      deviceName: payload.deviceName,
      ipAddress: payload.ipAddress,
      port: payload.port,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewerCubit, ViewerState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: state.isLiveViewVisible
              ? Scaffold(
                  key: const ValueKey('live-view'),
                  body: LiveStreamViewer(
                    frame: state.latestFrame,
                    connectionStatusLabel: state.connectionStatusLabel,
                    streamStatus: state.streamStatus,
                    onDisconnect: () =>
                        context.read<ViewerCubit>().disconnect(),
                  ),
                )
              : Scaffold(
                  key: const ValueKey('discovery-view'),
                  appBar: AppBar(
                    title: const Text('Viewer'),
                    actions: [
                      IconButton(
                        tooltip: 'Scan host QR code',
                        onPressed: state.phase == ViewerPhase.connecting
                            ? null
                            : _scanQrAndJoin,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () =>
                          context.read<ViewerCubit>().scanForHosts(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          _StatusCard(state: state),
                          const SizedBox(height: 16),
                          AppPrimaryButton(
                            label: state.phase == ViewerPhase.scanning
                                ? 'Scanning...'
                                : 'Scan for Hosts',
                            icon: Icons.search_rounded,
                            isLoading: state.phase == ViewerPhase.scanning,
                            onPressed:
                                state.canScan ||
                                    state.phase == ViewerPhase.scanning
                                ? () =>
                                      context.read<ViewerCubit>().scanForHosts()
                                : null,
                          ),
                          const SizedBox(height: 12),
                          state.phase == ViewerPhase.error ||
                                  state.phase == ViewerPhase.disconnected
                              ? AppSecondaryButton(
                                  label: 'Scan QR to Join',
                                  icon: Icons.qr_code_scanner_rounded,
                                  onPressed: _scanQrAndJoin,
                                )
                              : SizedBox.shrink(),
                          if (state.canDisconnect) ...[
                            const SizedBox(height: 12),
                            AppSecondaryButton(
                              label: 'Disconnect',
                              icon: Icons.link_off_rounded,
                              onPressed: () =>
                                  context.read<ViewerCubit>().disconnect(),
                            ),
                          ],
                          const SizedBox(height: 24),
                          AppSectionHeader(
                            title: 'Discovered Hosts',
                            subtitle: 'Hosts available on your local network',
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child:
                                state.phase == ViewerPhase.scanning &&
                                    state.discoveredHosts.isEmpty
                                ? const AppEmptyState(
                                    key: ValueKey('searching'),
                                    icon: Icons.radar_rounded,
                                    title: 'Searching the local network',
                                    message:
                                        'Looking for Peer View hosts on Wi‑Fi or hotspot.',
                                    searching: true,
                                  )
                                : state.discoveredHosts.isEmpty
                                ? const AppEmptyState(
                                    key: ValueKey('empty'),
                                    icon: Icons.wifi_off_rounded,
                                    title: 'No hosts found yet',
                                    message:
                                        'Make sure the host is streaming on the same Wi‑Fi or hotspot, or scan the host QR code.',
                                  )
                                : Column(
                                    key: ValueKey(
                                      'hosts-${state.discoveredHosts.length}',
                                    ),
                                    children: [
                                      for (
                                        var i = 0;
                                        i < state.discoveredHosts.length;
                                        i++
                                      )
                                        HostListTile(
                                          host: state.discoveredHosts[i],
                                          index: i,
                                          enabled:
                                              state.phase !=
                                              ViewerPhase.connecting,
                                          onConnect: () => context
                                              .read<ViewerCubit>()
                                              .connectToHost(
                                                state.discoveredHosts[i],
                                              ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
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
    final isLive =
        state.phase == ViewerPhase.streaming ||
        state.phase == ViewerPhase.connected;
    final isBusy =
        state.phase == ViewerPhase.scanning ||
        state.phase == ViewerPhase.connecting;

    return FadeSlideIn(
      child: AppCard(
        accentBorder: isLive,
        breathe: isLive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Status', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (isLive) ...[const LiveBadge(), const SizedBox(width: 8)],
                AppStatusChip(
                  label: _phaseLabel(state.phase),
                  color: _phaseColor(state.phase),
                  pulse: isLive || isBusy,
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedStatusText(
              text: _phaseLabel(state.phase),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (isBusy) ...[
              const SizedBox(height: 14),
              if (state.phase == ViewerPhase.scanning)
                const Center(child: SearchingRadar(size: 64))
              else
                const LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
            ],
            const SizedBox(height: 14),
            AppInfoRow(label: 'Connection', value: state.connectionStatusLabel),
            AppInfoRow(label: 'Stream', value: state.streamStatus),
            AppInfoRow(
              label: 'Scan target',
              value:
                  'port ${context.read<ViewerCubit>().discoveryPort}, '
                  'path ${context.read<ViewerCubit>().discoveryPath}',
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: state.selectedHost == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        AppInfoRow(
                          label: 'Selected',
                          value: state.selectedHost!.deviceName,
                        ),
                        AppInfoRow(
                          label: 'URL',
                          value: state.selectedHost!.websocketUrl,
                          selectable: true,
                        ),
                      ],
                    ),
            ),
            if (state.framesReceived > 0)
              AppInfoRow(label: 'Frames', value: '${state.framesReceived}'),
            if (state.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                state.lastError!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
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

  Color _phaseColor(ViewerPhase phase) {
    return switch (phase) {
      ViewerPhase.streaming || ViewerPhase.connected => AppColors.success,
      ViewerPhase.scanning || ViewerPhase.connecting => AppColors.warning,
      ViewerPhase.error => AppColors.error,
      ViewerPhase.initial ||
      ViewerPhase.hostsFound ||
      ViewerPhase.disconnected => AppColors.primary,
    };
  }
}
