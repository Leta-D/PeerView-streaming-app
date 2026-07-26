import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_state.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_event.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_log_entry.dart';
import 'package:peer_view_2/features/screen_streaming/models/stream_server_config.dart';
import 'package:peer_view_2/features/screen_streaming/models/streaming_exceptions.dart';
import 'package:peer_view_2/features/screen_streaming/repositories/screen_streaming_repository.dart';
import 'package:peer_view_2/features/screen_streaming/services/stream_logger.dart';

/// Coordinates host streaming state without performing capture or networking itself.
class ScreenStreamingCubit extends Cubit<ScreenStreamingState> {
  ScreenStreamingCubit({
    required ScreenStreamingRepository repository,
    required StreamLogger logger,
    this.serverConfig = const StreamServerConfig(),
  })  : _repository = repository,
        _logger = logger,
        super(const ScreenStreamingState()) {
    _eventSubscription = _repository.eventStream.listen(_handleStreamEvent);
    _logSubscription = _logger.logStream.listen(_handleLogEntry);
    unawaited(_initializeNetworkInfo());
  }

  final ScreenStreamingRepository _repository;
  final StreamLogger _logger;
  final StreamServerConfig serverConfig;

  StreamSubscription<StreamEvent>? _eventSubscription;
  StreamSubscription<StreamLogEntry>? _logSubscription;

  /// Live capture source for the host preview widget.
  Object? get previewStream => _repository.previewStream;

  Future<void> _initializeNetworkInfo() async {
    try {
      final info = await _repository.loadNetworkInfo(config: serverConfig);
      emit(
        state.copyWith(
          hostIpAddress: info.hostIpAddress,
          port: info.port,
          websocketUrl: info.websocketUrl,
          clearError: true,
        ),
      );
    } catch (error) {
      _logger.error('Failed to resolve host IP address', cause: error);
      emit(
        state.copyWith(
          status: ScreenStreamingStatus.error,
          lastError: error.toString(),
        ),
      );
    }
  }

  Future<void> startStreaming() async {
    if (!state.canStart) {
      return;
    }

    emit(
      state.copyWith(
        status: ScreenStreamingStatus.starting,
        framesCaptured: 0,
        framesBroadcast: 0,
        clearError: true,
      ),
    );

    try {
      await _repository.startStreaming(config: serverConfig);
      final info = _repository.networkInfo;

      emit(
        state.copyWith(
          status: ScreenStreamingStatus.waitingForClients,
          serverRunning: true,
          streaming: true,
          connectedClientCount: _repository.connectedClientCount,
          hostIpAddress: info?.hostIpAddress ?? state.hostIpAddress,
          port: info?.port ?? serverConfig.port,
          websocketUrl: info?.websocketUrl ?? state.websocketUrl,
        ),
      );
    } on ScreenCaptureException catch (error) {
      _logger.error('Permission or capture error', cause: error);
      await _repository.stopStreaming();
      emit(
        state.copyWith(
          status: ScreenStreamingStatus.error,
          serverRunning: false,
          streaming: false,
          lastError: error.message,
        ),
      );
    } on WebSocketServerException catch (error) {
      _logger.error('Server error', cause: error);
      await _repository.stopStreaming();
      emit(
        state.copyWith(
          status: ScreenStreamingStatus.error,
          serverRunning: false,
          streaming: false,
          lastError: error.message,
        ),
      );
    } catch (error) {
      _logger.error('Failed to start streaming', cause: error);
      await _repository.stopStreaming();
      emit(
        state.copyWith(
          status: ScreenStreamingStatus.error,
          serverRunning: false,
          streaming: false,
          lastError: error.toString(),
        ),
      );
    }
  }

  Future<void> stopStreaming() async {
    if (!state.canStop && state.status != ScreenStreamingStatus.error) {
      return;
    }

    emit(state.copyWith(status: ScreenStreamingStatus.stopping));

    try {
      await _repository.stopStreaming();
      emit(
        state.copyWith(
          status: ScreenStreamingStatus.stopped,
          serverRunning: false,
          streaming: false,
          connectedClientCount: 0,
          clearError: true,
        ),
      );
    } catch (error) {
      _logger.error('Failed to stop streaming', cause: error);
      emit(
        state.copyWith(
          status: ScreenStreamingStatus.error,
          lastError: error.toString(),
        ),
      );
    }
  }

  void _handleStreamEvent(StreamEvent event) {
    switch (event) {
      case StreamServerStartedEvent():
        emit(
          state.copyWith(
            serverRunning: true,
            hostIpAddress: _repository.networkInfo?.hostIpAddress,
            port: event.port,
            websocketUrl: event.websocketUrl,
          ),
        );
      case StreamServerStoppedEvent():
        emit(
          state.copyWith(
            serverRunning: false,
            connectedClientCount: 0,
          ),
        );
      case StreamClientConnectedEvent():
        emit(
          state.copyWith(
            status: _resolveActiveStatus(
              connectedClientCount: event.connectedClientCount,
              framesBroadcast: state.framesBroadcast,
            ),
            connectedClientCount: event.connectedClientCount,
          ),
        );
      case StreamClientDisconnectedEvent():
        emit(
          state.copyWith(
            status: event.connectedClientCount == 0
                ? ScreenStreamingStatus.waitingForClients
                : ScreenStreamingStatus.clientConnected,
            connectedClientCount: event.connectedClientCount,
          ),
        );
      case StreamFrameCapturedEvent():
        emit(
          state.copyWith(
            framesCaptured: event.sequenceNumber + 1,
            status: _resolveActiveStatus(
              connectedClientCount: state.connectedClientCount,
              framesBroadcast: state.framesBroadcast,
            ),
          ),
        );
      case StreamFrameBroadcastEvent(:final recipientCount):
        emit(
          state.copyWith(
            framesBroadcast: event.sequenceNumber + 1,
            status: recipientCount > 0
                ? ScreenStreamingStatus.streaming
                : _resolveActiveStatus(
                    connectedClientCount: state.connectedClientCount,
                    framesBroadcast: event.sequenceNumber + 1,
                  ),
          ),
        );
      case StreamFrameEncodedEvent():
        break;
      case StreamNetworkChangedEvent():
        emit(
          state.copyWith(
            hostIpAddress: event.hostIpAddress,
            websocketUrl: event.websocketUrl,
          ),
        );
      case StreamErrorEvent():
        _logger.error(event.message, cause: event.cause);
        emit(state.copyWith(lastError: event.message));
    }
  }

  ScreenStreamingStatus _resolveActiveStatus({
    required int connectedClientCount,
    required int framesBroadcast,
  }) {
    if (!state.streaming) {
      return state.status;
    }
    if (connectedClientCount == 0) {
      return ScreenStreamingStatus.waitingForClients;
    }
    if (framesBroadcast > 0) {
      return ScreenStreamingStatus.streaming;
    }
    return ScreenStreamingStatus.clientConnected;
  }

  void _handleLogEntry(StreamLogEntry entry) {
    final logs = [...state.recentLogs, entry];
    if (logs.length > 100) {
      logs.removeRange(0, logs.length - 100);
    }
    emit(state.copyWith(recentLogs: logs));
  }

  @override
  Future<void> close() async {
    await _eventSubscription?.cancel();
    await _logSubscription?.cancel();
    await _repository.stopStreaming();
    return super.close();
  }
}
