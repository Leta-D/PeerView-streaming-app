import 'dart:async';

import 'package:peer_view_2/features/screen_streaming/models/captured_frame.dart';
import 'package:peer_view_2/features/screen_streaming/models/host_network_info.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_event.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:peer_view_2/features/screen_streaming/repositories/screen_streaming_repository.dart';
import 'package:peer_view_2/features/screen_streaming/services/frame_encoder_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/impl/dart_websocket_server_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/network_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/screen_capture_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/stream_logger.dart';
import 'package:peer_view_2/features/screen_streaming/services/websocket_server_service.dart';

/// Wires the host streaming pipeline together without mixing responsibilities.
class ScreenStreamingRepositoryImpl implements ScreenStreamingRepository {
  ScreenStreamingRepositoryImpl({
    required ScreenCaptureService screenCaptureService,
    required FrameEncoderService frameEncoderService,
    required WebSocketServerService webSocketServerService,
    required NetworkService networkService,
    required StreamLogger logger,
  })  : _screenCaptureService = screenCaptureService,
        _frameEncoderService = frameEncoderService,
        _webSocketServerService = webSocketServerService,
        _networkService = networkService,
        _logger = logger {
    _serverEventSubscription =
        _webSocketServerService.eventStream.listen(_eventController.add);
  }

  final ScreenCaptureService _screenCaptureService;
  final FrameEncoderService _frameEncoderService;
  final WebSocketServerService _webSocketServerService;
  final NetworkService _networkService;
  final StreamLogger _logger;

  final StreamController<StreamEvent> _eventController =
      StreamController<StreamEvent>.broadcast();

  StreamSubscription<dynamic>? _frameSubscription;
  StreamSubscription<HostNetworkInfo>? _networkSubscription;
  StreamSubscription<StreamEvent>? _serverEventSubscription;
  HostNetworkInfo? _networkInfo;
  StreamServerConfig _config = const StreamServerConfig();
  bool _streaming = false;
  bool _processingFrame = false;

  @override
  bool get isServerRunning => _webSocketServerService.isRunning;

  @override
  bool get isStreaming => _streaming;

  @override
  int get connectedClientCount => _webSocketServerService.connectedClientCount;

  @override
  HostNetworkInfo? get networkInfo => _networkInfo;

  @override
  Object? get previewStream => _screenCaptureService.previewStream;

  @override
  Stream<StreamEvent> get eventStream => _eventController.stream;

  @override
  Future<HostNetworkInfo> loadNetworkInfo({StreamServerConfig config = const StreamServerConfig()}) async {
    _config = config;
    _networkInfo = await _networkService.getHostNetworkInfo(
      port: config.port,
      webSocketPath: config.webSocketPath,
    );
    _listenToNetworkChanges();
    return _networkInfo!;
  }

  void _listenToNetworkChanges() {
    _networkSubscription?.cancel();
    _networkSubscription = _networkService
        .watchNetworkInfo(
          port: _config.port,
          webSocketPath: _config.webSocketPath,
        )
        .listen(
      (info) {
        _networkInfo = info;
        _updateServerHostMetadata(info.hostIpAddress);
        _eventController.add(
          StreamNetworkChangedEvent(
            timestamp: DateTime.now(),
            hostIpAddress: info.hostIpAddress,
            websocketUrl: info.websocketUrl,
          ),
        );
      },
    );
  }

  void _updateServerHostMetadata(String hostIpAddress) {
    final server = _webSocketServerService;
    if (server is DartWebSocketServerService) {
      server.updateHostMetadata(hostIpAddress: hostIpAddress);
    }
  }

  @override
  Future<void> startStreaming({StreamServerConfig config = const StreamServerConfig()}) async {
    if (_streaming) {
      return;
    }

    _config = config;
    _networkInfo = await _networkService.getHostNetworkInfo(
      port: config.port,
      webSocketPath: config.webSocketPath,
    );
    _listenToNetworkChanges();
    _updateServerHostMetadata(_networkInfo!.hostIpAddress);

    _logger.info('Starting WebSocket server on port ${config.port}');
    await _webSocketServerService.start(config: config);
    _logger.info('WebSocket server started at ${_networkInfo!.websocketUrl}');

    _logger.info('Starting screen capture');
    await _screenCaptureService.startCapture();
    _logger.info('Screen capture started');

    _frameSubscription = _screenCaptureService.frameStream.listen(
      (frame) => unawaited(_processFrame(frame)),
      onError: (Object error) {
        _logger.error('Screen capture stream error', cause: error);
        _eventController.add(
          StreamErrorEvent(
            timestamp: DateTime.now(),
            message: 'Screen capture stream error',
            cause: error,
          ),
        );
      },
    );

    _streaming = true;
  }

  Future<void> _processFrame(CapturedFrame frame) async {
    if (!_streaming || _processingFrame) {
      return;
    }

    _processingFrame = true;
    final timestamp = DateTime.now();
    _eventController.add(
      StreamFrameCapturedEvent(
        timestamp: timestamp,
        sequenceNumber: frame.sequenceNumber,
      ),
    );
    _logger.info('Frame captured seq=${frame.sequenceNumber}');

    try {
      final encoded = _frameEncoderService.encode(frame);
      _eventController.add(
        StreamFrameEncodedEvent(
          timestamp: DateTime.now(),
          sequenceNumber: encoded.sequenceNumber,
          payloadBytes: encoded.data.length,
        ),
      );
      _logger.info(
        'Frame encoded seq=${encoded.sequenceNumber} (${encoded.data.length} bytes)',
      );

      await _webSocketServerService.broadcast(encoded);
      _logger.info(
        'Frame broadcast seq=${encoded.sequenceNumber} to $connectedClientCount client(s)',
      );
    } catch (error) {
      _logger.error('Streaming pipeline error', cause: error);
      _eventController.add(
        StreamErrorEvent(
          timestamp: DateTime.now(),
          message: 'Streaming pipeline error',
          cause: error,
        ),
      );
    } finally {
      _processingFrame = false;
    }
  }

  @override
  Future<void> stopStreaming() async {
    if (!_streaming && !isServerRunning && !_screenCaptureService.isCapturing) {
      return;
    }

    _streaming = false;

    await _frameSubscription?.cancel();
    _frameSubscription = null;

    if (_screenCaptureService.isCapturing) {
      _logger.info('Stopping screen capture');
      await _screenCaptureService.stopCapture();
      _logger.info('Screen capture stopped');
    }

    if (isServerRunning) {
      _logger.info('Stopping WebSocket server');
      await _webSocketServerService.stop();
      _logger.info('WebSocket server stopped');
    }
  }

  Future<void> dispose() async {
    await _networkSubscription?.cancel();
    await _serverEventSubscription?.cancel();
    await stopStreaming();
    await _eventController.close();
  }
}
