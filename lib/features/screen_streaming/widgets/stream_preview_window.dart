import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _isRendererReady && widget.previewStream != null
            ? ColoredBox(
                color: Colors.black,
                child: RTCVideoView(
                  _renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              )
            : const ColoredBox(
                color: Colors.black87,
                child: Center(child: Icon(Icons.videocam_outlined, color: Colors.white54)),
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
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index];
        final color = switch (entry.level) {
          StreamLogLevel.info => Theme.of(context).colorScheme.onSurface,
          StreamLogLevel.warning => Colors.orange,
          StreamLogLevel.error => Theme.of(context).colorScheme.error,
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
