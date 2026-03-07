// screen_share_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screen_share_event.dart';
import 'screen_share_state.dart';
import 'screen_share_service.dart';

class ScreenShareBloc extends Bloc<ScreenShareEvent, ScreenShareState> {
  ScreenShareBloc() : super(ScreenShareInitial()) {
    on<StartScreenShare>(_onStart);
    on<StopScreenShare>(_onStop);
  }

  final ScreenShareService service = ScreenShareService();

  Future<void> _onStart(
    StartScreenShare event,
    Emitter<ScreenShareState> emit,
  ) async {
    emit(ScreenShareLoading());
    try {
      // final pc = await service.startStream();
      // emit(ScreenShareStreaming(pc));
    } catch (e) {
      emit(ScreenShareError(e.toString()));
    }
  }

  Future<void> _onStop(
    StopScreenShare event,
    Emitter<ScreenShareState> emit,
  ) async {
    await service.stopStream();
    emit(ScreenShareInitial());
  }
}
