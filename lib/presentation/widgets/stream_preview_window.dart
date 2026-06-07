import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_log_entry.dart';

/// Compact live preview of the host screen while streaming.
class StreamPreviewWindow extends StatefulWidget {
  const StreamPreviewWindow({
    super.key,
    required this.previewStream,
  });

  final Object? previewStream;

  @override
  State<StreamPreviewWindow> createState() => _StreamPreviewWindowState();
}

class _StreamPreviewWindowState extends State<StreamPreviewWindow> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _isRendererReady = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  @override
  void didUpdateWidget(covariant StreamPreviewWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewStream != widget.previewStream) {
      _attachStream();
    }
  }

  Future<void> _initializeRenderer() async {
    await _renderer.initialize();
    if (!mounted) {
      return;
    }
    setState(() => _isRendererReady = true);
    _attachStream();
  }

  void _attachStream() {
    if (!_isRendererReady) {
      return;
    }
    _renderer.srcObject = widget.previewStream as MediaStream?;
  }

  @override
  void dispose() {
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderAccent),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isRendererReady && widget.previewStream != null
              ? ColoredBox(
                  color: AppColors.background,
                  child: RTCVideoView(
                    _renderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                )
              : const ColoredBox(
                  color: AppColors.surfaceMuted,
                  child: Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      color: AppColors.textMuted,
                      size: 32,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Scrollable list of recent host streaming log entries.
class StreamEventLog extends StatelessWidget {
  const StreamEventLog({
    super.key,
    required this.entries,
  });

  final List<StreamLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'No events yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final visibleEntries = entries.length > 8
        ? entries.sublist(entries.length - 8)
        : entries;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleEntries.length,
      separatorBuilder: (_, __) => const Divider(height: 14),
      itemBuilder: (context, index) {
        final entry = visibleEntries[visibleEntries.length - 1 - index];
        final color = switch (entry.level) {
          StreamLogLevel.info => AppColors.textSecondary,
          StreamLogLevel.warning => AppColors.warning,
          StreamLogLevel.error => AppColors.error,
        };

        return Text(
          '[${_formatTime(entry.timestamp)}] ${entry.message}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
