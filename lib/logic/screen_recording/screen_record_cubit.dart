import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peer_view/logic/screen_recording/screen_record_service.dart';
import 'package:peer_view/logic/screen_recording/screen_record_state.dart';

class ScreenRecordCubit extends Cubit<ScreenRecordState> {
  ScreenRecordCubit() : super(InitialScreenRecordState());

  final ScreenRecordService _service = ScreenRecordService();

  Future<void> startRecording() async {
    try {
      emit(LoadingScreenRecordState());

      if (state is! RecordingScreenRecordState) {
        MediaStream mediaStream = await _service.captureScreen();
        emit(RecordingScreenRecordState(screenMedia: mediaStream));
      }
    } catch (e) {
      emit(ErrorScreenRecordState(errorMessage: e.toString()));
    }
  }

  Future<void> stopRecording() async {
    try {
      await _service.stop();

      emit(StoppedScreenRecordState());
    } catch (e) {
      emit(ErrorScreenRecordState(errorMessage: e.toString()));
    }
  }
}
