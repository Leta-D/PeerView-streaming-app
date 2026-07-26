import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:peer_view_2/features/screen_viewer/models/decoded_frame.dart';

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
        ColoredBox(
          color: Colors.black,
          child: frame == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                )
              : InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: Image.memory(
                      frame!.imageBytes,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
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
                      child: _StatusChip(
                        label: connectionStatusLabel,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(label: streamStatus),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton.icon(
                    onPressed: onDisconnect,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.link_off),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
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
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.memory(imageBytes, fit: BoxFit.cover),
      ),
    );
  }
}
