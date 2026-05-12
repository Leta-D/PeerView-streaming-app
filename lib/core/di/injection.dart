import 'package:get_it/get_it.dart';
import 'package:peer_view_2/core/settings/stream_settings_store.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_cubit.dart';
import 'package:peer_view_2/features/screen_streaming/repositories/screen_streaming_repository.dart';
import 'package:peer_view_2/features/screen_streaming/repositories/screen_streaming_repository_impl.dart';
import 'package:peer_view_2/features/screen_streaming/services/frame_encoder_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/impl/dart_websocket_server_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/impl/device_network_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/impl/in_memory_stream_logger.dart';
import 'package:peer_view_2/features/screen_streaming/services/impl/jpeg_frame_encoder_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/impl/webrtc_screen_capture_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/network_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/screen_capture_service.dart';
import 'package:peer_view_2/features/screen_streaming/services/stream_logger.dart';
import 'package:peer_view_2/features/screen_streaming/services/websocket_server_service.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_cubit.dart';
import 'package:peer_view_2/features/screen_viewer/repositories/viewer_repository.dart';
import 'package:peer_view_2/features/screen_viewer/repositories/viewer_repository_impl.dart';
import 'package:peer_view_2/features/screen_viewer/services/frame_decoder_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/host_discovery_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/impl/jpeg_frame_decoder_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/impl/lan_subnet_host_discovery_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/impl/reconnecting_websocket_client_service.dart';
import 'package:peer_view_2/features/screen_viewer/services/websocket_client_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

/// Registers host and viewer dependencies.
Future<void> configureDependencies() async {
  if (sl.isRegistered<ScreenStreamingRepository>()) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<StreamSettingsStore>(StreamSettingsStore(prefs));

  _registerHostDependencies();
  _registerViewerDependencies();
}

void _registerHostDependencies() {
  sl.registerLazySingleton<StreamLogger>(InMemoryStreamLogger.new);
  sl.registerLazySingleton<ScreenCaptureService>(WebRtcScreenCaptureService.new);
  sl.registerLazySingleton<FrameEncoderService>(JpegFrameEncoderService.new);
  sl.registerLazySingleton<WebSocketServerService>(DartWebSocketServerService.new);
  sl.registerLazySingleton<NetworkService>(DeviceNetworkService.new);

  sl.registerLazySingleton<ScreenStreamingRepository>(
    () => ScreenStreamingRepositoryImpl(
      screenCaptureService: sl<ScreenCaptureService>(),
      frameEncoderService: sl<FrameEncoderService>(),
      webSocketServerService: sl<WebSocketServerService>(),
      networkService: sl<NetworkService>(),
      logger: sl<StreamLogger>(),
    ),
  );

  sl.registerFactory(
    () => ScreenStreamingCubit(
      repository: sl<ScreenStreamingRepository>(),
      logger: sl<StreamLogger>(),
      settingsStore: sl<StreamSettingsStore>(),
    ),
  );
}

void _registerViewerDependencies() {
  sl.registerLazySingleton<HostDiscoveryService>(LanSubnetHostDiscoveryService.new);
  sl.registerLazySingleton<WebSocketClientService>(ReconnectingWebSocketClientService.new);
  sl.registerLazySingleton<FrameDecoderService>(JpegFrameDecoderService.new);

  sl.registerLazySingleton<ViewerRepository>(
    () => ViewerRepositoryImpl(
      hostDiscoveryService: sl<HostDiscoveryService>(),
      webSocketClientService: sl<WebSocketClientService>(),
      frameDecoderService: sl<FrameDecoderService>(),
    ),
  );

  sl.registerFactory(
    () => ViewerCubit(
      repository: sl<ViewerRepository>(),
      settingsStore: sl<StreamSettingsStore>(),
    ),
  );
}
