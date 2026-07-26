/// Thrown when host discovery fails.
class HostDiscoveryException implements Exception {
  const HostDiscoveryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'HostDiscoveryException: $message';
}

/// Thrown when the viewer WebSocket client fails.
class ViewerConnectionException implements Exception {
  const ViewerConnectionException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ViewerConnectionException: $message';
}

/// Thrown when a received frame cannot be decoded.
class FrameDecodeException implements Exception {
  const FrameDecodeException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'FrameDecodeException: $message';
}
