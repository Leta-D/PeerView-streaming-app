abstract class BroadcastState {}

class BroadcastingInitialState extends BroadcastState {}

class BroadcastingState extends BroadcastState {}

class BroadcastingStoppedState extends BroadcastState {}

class BroadcastingErrorState extends BroadcastState {
  String errorMessage;

  BroadcastingErrorState({required this.errorMessage});
}
