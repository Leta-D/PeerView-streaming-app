// screen_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// Events
abstract class ScreenEvent {}

class SetLocalStream extends ScreenEvent {
  final MediaStream stream;
  SetLocalStream(this.stream);
}

// States
class ScreenState {
  final MediaStream? stream;
  ScreenState({this.stream});
}

// BLoC
class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  ScreenBloc() : super(ScreenState()) {
    on<SetLocalStream>((event, emit) {
      emit(ScreenState(stream: event.stream));
    });
  }
}
// local_screen_preview.dart

class LocalScreenPreview extends StatelessWidget {
  const LocalScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenBloc, ScreenState>(
      builder: (context, state) {
        if (state.stream == null) {
          return const Center(child: Text("Waiting for stream..."));
        }

        return RTCVideoView(
          RTCVideoRenderer()..srcObject = state.stream,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      },
    );
  }
}

// preview_page.dart

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
    _startScreenCapture();
  }

  Future<void> _startScreenCapture() async {
    try {
      // Capture screen (Android MediaProjection)
      final stream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });

      // Send to BLoC
      context.read<ScreenBloc>().add(SetLocalStream(stream));

      // Also attach to local renderer for immediate preview
      _renderer.srcObject = stream;
    } catch (e) {
      debugPrint("Screen capture failed: $e");
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Host Screen Preview")),
      body: RTCVideoView(
        _renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }
}
