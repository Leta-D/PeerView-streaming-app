/// Configuration for the host WebSocket server.
class StreamServerConfig {
  const StreamServerConfig({
    this.port = 8080,
    this.webSocketPath = '/stream',
  });

  final int port;
  final String webSocketPath;
}
