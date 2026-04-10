import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/offer_logic/hosts/broadcast_cubit.dart';
import 'package:peer_view/logic/offer_logic/hosts/broadcast_state.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_bloc.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_event.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_state.dart';
import 'package:peer_view/logic/screen_recording/screen_record_cubit.dart';
import 'package:peer_view/logic/screen_recording/screen_record_state.dart';
import 'package:peer_view/logic/work_flow_control/work_flow_state.dart';

class WorkFlowCubit extends Cubit<WorkFlowState> {
  final ScreenRecordCubit screenRecordCubit;
  final BroadcastCubit broadcastCubit;
  final HostBloc hostBloc;

  WorkFlowCubit({
    required this.screenRecordCubit,
    required this.broadcastCubit,
    required this.hostBloc,
  }) : super(WorkFlowInitialState());

  Future<void> startHostTask() async {
    try {
      emit(WorkFlowFirstState(workSuccess: false));

      await screenRecordCubit.startRecording();
      if (screenRecordCubit.state is RecordingScreenRecordState) {
        emit(WorkFlowFirstState(workSuccess: true));

        await Future.delayed(2.seconds);

        emit(WorkFlowSecondState(workSuccess: false));
        await broadcastCubit.startBroadcast();
        if (broadcastCubit.state is BroadcastingState) {
          emit(WorkFlowSecondState(workSuccess: true));

          await Future.delayed(2.seconds);

          emit(WorkFlowTheirdState(workSuccess: false));
          hostBloc.add(StartHostStreamEvent());
          if (hostBloc.state is HostStreamingState) {
            emit(WorkFlowTheirdState(workSuccess: true));

            await Future.delayed(2.seconds);

            emit(WorkFlowSuccessState());
          } else if (hostBloc.state is HostStreamErrorState) {
            emit(
              WorkFlowErrorState(
                errorMessage:
                    (hostBloc.state as HostStreamErrorState).errorMessage,
              ),
            );
            // final cs = hostBloc.state;
            // if (cs is HostStreamErrorState) {
            //   emit(WorkFlowErrorState(errorMessage: cs.errorMessage));
            // }
          }
        } else if (broadcastCubit.state is BroadcastingErrorState) {
          emit(
            WorkFlowErrorState(
              errorMessage:
                  (broadcastCubit.state as BroadcastingErrorState).errorMessage,
            ),
          );
          // final cs = broadcastCubit.state;
          // if (cs is BroadcastingErrorState) {
          //   emit(WorkFlowErrorState(errorMessage: cs.errorMessage));
          // }
        }
      } else if (screenRecordCubit.state is ErrorScreenRecordState) {
        emit(
          WorkFlowErrorState(
            errorMessage: (screenRecordCubit.state as ErrorScreenRecordState)
                .errorMessage,
          ),
        );
        // final cs = screenRecordCubit.state;
        // if (cs is ErrorScreenRecordState) {
        //   emit(WorkFlowErrorState(errorMessage: cs.errorMessage));
        // }
      }
    } catch (e) {
      emit(WorkFlowErrorState(errorMessage: e.toString()));
    }
  }

  Future<void> startHostTask2() async {
    try {
      emit(WorkFlowFirstState(workSuccess: false));
      if (screenRecordCubit.state is RecordingScreenRecordState) {
        emit(WorkFlowFirstState(workSuccess: true));
        await Future.delayed(2.seconds);

        emit(WorkFlowSecondState(workSuccess: false));
        await broadcastCubit.startBroadcast();
        if (broadcastCubit.state is BroadcastingState) {
          emit(WorkFlowSecondState(workSuccess: true));
          await Future.delayed(2.seconds);

          emit(WorkFlowTheirdState(workSuccess: false));
          hostBloc.add(StartHostStreamEvent());
          if (hostBloc.state is HostStreamingState) {
            emit(WorkFlowTheirdState(workSuccess: true));
            await Future.delayed(2.seconds);

            emit(WorkFlowSuccessState());
          }
        }
      }

      if (screenRecordCubit.state is ErrorScreenRecordState) {
        throw ((screenRecordCubit.state as ErrorScreenRecordState)
            .errorMessage);
      }
      if (broadcastCubit.state is BroadcastingErrorState) {
        throw ((broadcastCubit.state as BroadcastingErrorState).errorMessage);
      }
      if (hostBloc.state is HostStreamErrorState) {
        throw ((hostBloc.state as HostStreamErrorState).errorMessage);
      }
    } catch (e) {
      emit(WorkFlowErrorState(errorMessage: e.toString()));
    }
  }

  Future<void> stopHostTask() async {
    try {
      hostBloc.add(StopHostStreamEvent());
      broadcastCubit.stopBroadcast();
      await screenRecordCubit.stopRecording();

      emit(WorkFlowStopedState());
    } catch (e) {
      emit(WorkFlowErrorState(errorMessage: e.toString()));
    }
  }
}
