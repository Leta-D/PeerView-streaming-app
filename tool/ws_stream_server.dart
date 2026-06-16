import 'dart:io';
import 'dart:typed_data';

/// Local WebSocket relay server for testing screen streaming from the app.
///
/// Usage:
///   dart run tool/ws_stream_server.dart
///
/// Endpoints:
/// - `ws://<host>:8080/stream`  Flutter app sends frames here
/// - `ws://<host>:8080/viewer`  Browser viewer receives forwarded frames
/// - `http://<host>:8080/`      Opens the built-in viewer page
/// these endpoints and ports can be modified in the app's stream settings screen.
Future<void> main() async {
  final viewers = <WebSocket>{};
  WebSocket? broadcaster;

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  stdout.writeln('Stream server running on http://${await _localIp()}:8080');
  stdout.writeln('App URL:    ws://${await _localIp()}:8080/stream');
  stdout.writeln('Viewer URL: http://${await _localIp()}:8080/');

  await for (final request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final path = request.uri.path;
      final socket = await WebSocketTransformer.upgrade(request);

      if (path == '/stream') {
        stdout.writeln('Broadcaster connected');
        broadcaster?.close();
        broadcaster = socket;

        socket.listen(
          (message) {
            if (message is String) {
              stdout.writeln('Control: $message');
              return;
            }

            if (message is List<int>) {
              _forwardFrame(viewers, Uint8List.fromList(message));
            }
          },
          onDone: () {
            stdout.writeln('Broadcaster disconnected');
            if (broadcaster == socket) {
              broadcaster = null;
            }
          },
        );
        continue;
      }

      if (path == '/viewer') {
        stdout.writeln('Viewer connected (${viewers.length + 1})');
        viewers.add(socket);
        socket.done.then((_) {
          viewers.remove(socket);
          stdout.writeln('Viewer disconnected (${viewers.length} remaining)');
        });
        continue;
      }

      await socket.close();
      continue;
    }

    if (request.uri.path == '/' || request.uri.path == '/index.html') {
      request.response.headers.contentType = ContentType.html;
      request.response.write(_viewerHtml);
      await request.response.close();
      continue;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}

void _forwardFrame(Set<WebSocket> viewers, Uint8List frame) {
  for (final viewer in viewers.toList()) {
    try {
      viewer.add(frame);
    } catch (_) {
      viewers.remove(viewer);
    }
  }
}

Future<String> _localIp() async {
  for (final interface in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  )) {
    for (final address in interface.addresses) {
      if (!address.isLoopback) {
        return address.address;
      }
    }
  }
  return '127.0.0.1';
}

const _viewerHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Peer View 2 Stream Viewer</title>
  <style>
    body {
      margin: 0;
      font-family: sans-serif;
      background: #111;
      color: #f5f5f5;
      display: grid;
      place-items: center;
      min-height: 100vh;
    }
    main {
      width: min(960px, 96vw);
      display: grid;
      gap: 12px;
    }
    img {
      width: 100%;
      background: #000;
      border-radius: 12px;
      border: 1px solid #333;
      min-height: 240px;
      object-fit: contain;
    }
    .meta {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      font-size: 14px;
      color: #bbb;
    }
  </style>
</head>
<body>
  <main>
    <h1>Peer View 2 Live Stream</h1>
    <img id="frame" alt="Waiting for stream..." />
    <div class="meta">
      <span id="status">Connecting...</span>
      <span id="stats">0 frames</span>
    </div>
  </main>
  <script>
    const frame = document.getElementById('frame');
    const status = document.getElementById('status');
    const stats = document.getElementById('stats');
    let count = 0;

    const wsUrl = 'ws://' + location.host + '/viewer';
    const socket = new WebSocket(wsUrl);
    socket.binaryType = 'arraybuffer';

    socket.onopen = () => {
      status.textContent = 'Connected. Waiting for broadcaster...';
    };

    socket.onmessage = (event) => {
      if (!(event.data instanceof ArrayBuffer)) {
        return;
      }

      const bytes = new Uint8Array(event.data);
      if (bytes.length <= 24) {
        return;
      }

      const blob = new Blob([bytes.subarray(24)], { type: 'image/jpeg' });
      const url = URL.createObjectURL(blob);
      frame.src = url;
      count += 1;
      stats.textContent = count + ' frames';
      status.textContent = 'Live';
    };

    socket.onclose = () => {
      status.textContent = 'Disconnected';
    };

    socket.onerror = () => {
      status.textContent = 'Connection error';
    };
  </script>
</body>
</html>
''';
