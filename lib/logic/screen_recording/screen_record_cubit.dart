import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/screen_recording/screen_record_service.dart';
import 'package:peer_view/logic/screen_recording/screen_record_state.dart';

class ScreenRecordCubit extends Cubit<ScreenRecordState> {
  final ScreenRecordService _service;

  ScreenRecordCubit(this._service) : super(ScreenRecordState.initial());

  Future<void> startRecording() async {
    try {
      emit(state.copyWith(status: ScreenRecordStatus.requestingPermission));

      await _service.start();

      emit(state.copyWith(status: ScreenRecordStatus.recording));
    } catch (e) {
      emit(
        state.copyWith(status: ScreenRecordStatus.error, message: e.toString()),
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      await _service.stop();

      emit(state.copyWith(status: ScreenRecordStatus.stopped));
    } catch (e) {
      emit(
        state.copyWith(status: ScreenRecordStatus.error, message: e.toString()),
      );
    }
  }
}
