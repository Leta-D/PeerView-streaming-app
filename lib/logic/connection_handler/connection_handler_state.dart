abstract class ConnectionHandlerState {}

class ConnectionHandlerInitialState extends ConnectionHandlerState {}

class ConnectionHandlerLoadingState extends ConnectionHandlerState {}

class ConnectionHandlerLoadedState extends ConnectionHandlerState {
  final bool isConected;
  ConnectionHandlerLoadedState({required this.isConected});
}

class ConnectionHandlerErrorState extends ConnectionHandlerState {
  final String errorMessage;

  ConnectionHandlerErrorState({required this.errorMessage});
}
