abstract class WorkFlowState {}

class WorkFlowInitialState extends WorkFlowState {}

class WorkFlowFirstState extends WorkFlowState {
  bool workSuccess;
  WorkFlowFirstState({required this.workSuccess});
}

class WorkFlowSecondState extends WorkFlowState {
  bool workSuccess;
  WorkFlowSecondState({required this.workSuccess});
}

class WorkFlowTheirdState extends WorkFlowState {
  bool workSuccess;
  WorkFlowTheirdState({required this.workSuccess});
}

class WorkFlowStopedState extends WorkFlowState {}

class WorkFlowSuccessState extends WorkFlowState {}

class WorkFlowErrorState extends WorkFlowState {
  String errorMessage;
  WorkFlowErrorState({required this.errorMessage});
}
