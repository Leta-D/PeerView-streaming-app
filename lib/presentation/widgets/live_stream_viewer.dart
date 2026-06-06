import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

/// Full-screen live stream viewer for decoded JPEG frames.
class LiveStreamViewer extends StatelessWidget {
  const LiveStreamViewer({
    super.key,
    required this.frame,
    required this.onDisconnect,
    required this.connectionStatusLabel,
    required this.streamStatus,
  });

  final DecodedFrame? frame;
  final VoidCallback onDisconnect;
  final String connectionStatusLabel;
  final String streamStatus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: ColoredBox(
              color: AppColors.background,
              child: frame == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for frames…',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            streamStatus,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Center(
                        child: Image.memory(
                          frame!.imageBytes,
                          gaplessPlayback: true,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            'Received a frame but could not decode the image.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppStatusChip(
                        label: connectionStatusLabel,
                        color: AppColors.primary,
                        pulse: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const LiveBadge(),
                    const SizedBox(width: 8),
                    AppStatusChip(
                      label: streamStatus,
                      color: AppColors.success,
                      pulse: streamStatus.toLowerCase().contains('live'),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton.icon(
                    onPressed: onDisconnect,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Small thumbnail preview for the latest decoded frame.
class StreamThumbnail extends StatelessWidget {
  const StreamThumbnail({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.memory(imageBytes, fit: BoxFit.cover),
      ),
    );
  }
}
