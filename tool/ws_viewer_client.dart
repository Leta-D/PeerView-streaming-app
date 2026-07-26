import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Simple viewer client for testing the host WebSocket stream (Phase 1).
///
/// Usage:
///   dart run tool/ws_viewer_client.dart ws://192.168.43.1:8080/stream
Future<void> main(List<String> args) async {
  final url = args.isNotEmpty ? args.first : 'ws://127.0.0.1:8080/stream';
  stdout.writeln('Connecting to $url');

  final socket = await WebSocket.connect(url);
  var frameCount = 0;

  socket.listen(
    (message) {
      if (message is String) {
        stdout.writeln('Control: $message');
        return;
      }

      if (message is List<int>) {
        frameCount++;
        final bytes = Uint8List.fromList(message);
        if (bytes.length > 24) {
          stdout.writeln('Frame #$frameCount received (${bytes.length - 24} JPEG bytes)');
        }
      }
    },
    onDone: () => stdout.writeln('Disconnected'),
    onError: (Object error) => stdout.writeln('Error: $error'),
  );
}

/// Decodes a PV2 frame packet for future viewer tooling.
Map<String, dynamic>? decodeControlMessage(String message) {
  try {
    return jsonDecode(message) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
