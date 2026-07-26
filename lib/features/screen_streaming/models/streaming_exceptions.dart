/// Thrown when screen capture fails.
class ScreenCaptureException implements Exception {
  const ScreenCaptureException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ScreenCaptureException: $message';
}

/// Thrown when the WebSocket server fails.
class WebSocketServerException implements Exception {
  const WebSocketServerException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'WebSocketServerException: $message';
}

/// Thrown when frame encoding fails.
class FrameEncoderException implements Exception {
  const FrameEncoderException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'FrameEncoderException: $message';
}

/// Thrown when the viewer client fails to connect to a host stream.
class ClientConnectionException implements Exception {
  const ClientConnectionException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ClientConnectionException: $message';
}
